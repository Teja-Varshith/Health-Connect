import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_connect/features/community/repository/community_repository.dart';
import 'package:health_connect/models/community_post_model.dart';
import 'package:health_connect/models/comment_model.dart';
import 'package:health_connect/models/community_group_model.dart';
import 'package:health_connect/providers/user_provider.dart';
import 'package:health_connect/utils/storage_methods.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

// ─── Stream Providers ────────────────────────────────────────────────────────

final feedPostsProvider = StreamProvider<List<CommunityPost>>((ref) {
  return ref.watch(communityRepositoryProvider).watchFeedPosts();
});

final groupPostsProvider =
    StreamProvider.family<List<CommunityPost>, String>((ref, groupId) {
  return ref.watch(communityRepositoryProvider).watchGroupPosts(groupId);
});

final commentsProvider =
    StreamProvider.family<List<Comment>, String>((ref, postId) {
  return ref.watch(communityRepositoryProvider).watchComments(postId);
});

final allGroupsProvider = StreamProvider<List<CommunityGroup>>((ref) {
  return ref.watch(communityRepositoryProvider).watchAllGroups();
});

// ─── Create Post Controller ──────────────────────────────────────────────────

class CreatePostState {
  final bool isLoading;
  final Uint8List? imageBytes;
  final String? errorMessage;

  const CreatePostState({
    this.isLoading = false,
    this.imageBytes,
    this.errorMessage,
  });

  CreatePostState copyWith({
    bool? isLoading,
    Uint8List? imageBytes,
    String? errorMessage,
    bool clearImage = false,
  }) {
    return CreatePostState(
      isLoading: isLoading ?? this.isLoading,
      imageBytes: clearImage ? null : (imageBytes ?? this.imageBytes),
      errorMessage: errorMessage,
    );
  }
}

class CreatePostController extends StateNotifier<CreatePostState> {
  final Ref _ref;
  final _uuid = const Uuid();

  CreatePostController({required Ref ref})
      : _ref = ref,
        super(const CreatePostState());

  Future<void> pickImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await File(picked.path).readAsBytes();
      state = state.copyWith(imageBytes: bytes);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to pick image: $e');
    }
  }

  Future<void> captureImage() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        imageQuality: 80,
      );
      if (picked == null) return;
      final bytes = await File(picked.path).readAsBytes();
      state = state.copyWith(imageBytes: bytes);
    } catch (e) {
      state = state.copyWith(errorMessage: 'Failed to capture image: $e');
    }
  }

  void removeImage() {
    state = state.copyWith(clearImage: true);
  }

  Future<bool> submitPost({
    required String title,
    required String body,
    required bool isAnonymous,
    String? groupId,
  }) async {
    final user = _ref.read(userProvider);
    if (user == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      String? imageUrl;
      if (state.imageBytes != null) {
        imageUrl = await StorageMethods().uploadCommunityImage(
          state.imageBytes!,
        );
      }

      final postId = _uuid.v4();
      final post = CommunityPost(
        postId: postId,
        authorId: user.uid,
        authorName: user.name,
        isAnonymous: isAnonymous,
        groupId: groupId,
        title: title,
        body: body,
        imageUrl: imageUrl,
      );

      await _ref.read(communityRepositoryProvider).createPost(post);
      state = const CreatePostState(); // Reset
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create post: $e',
      );
      return false;
    }
  }

  void reset() {
    state = const CreatePostState();
  }
}

final createPostControllerProvider =
    StateNotifierProvider<CreatePostController, CreatePostState>((ref) {
  return CreatePostController(ref: ref);
});

// ─── Create Group Controller ─────────────────────────────────────────────────

class CreateGroupController extends StateNotifier<bool> {
  final Ref _ref;
  final _uuid = const Uuid();

  CreateGroupController({required Ref ref})
      : _ref = ref,
        super(false);

  Future<bool> createGroup({
    required String name,
    required String description,
    String? iconEmoji,
  }) async {
    final user = _ref.read(userProvider);
    if (user == null) return false;

    state = true; // loading
    try {
      final groupId = _uuid.v4();
      final group = CommunityGroup(
        groupId: groupId,
        name: name,
        description: description,
        iconEmoji: iconEmoji,
        createdBy: user.uid,
        memberIds: [user.uid],
      );
      await _ref.read(communityRepositoryProvider).createGroup(group);
      state = false;
      return true;
    } catch (e) {
      state = false;
      return false;
    }
  }
}

final createGroupControllerProvider =
    StateNotifierProvider<CreateGroupController, bool>((ref) {
  return CreateGroupController(ref: ref);
});
