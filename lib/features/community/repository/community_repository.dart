import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_connect/models/community_post_model.dart';
import 'package:health_connect/models/comment_model.dart';
import 'package:health_connect/models/community_group_model.dart';

final communityRepositoryProvider = Provider<CommunityRepository>((ref) {
  return CommunityRepository(firestore: FirebaseFirestore.instance);
});

class CommunityRepository {
  final FirebaseFirestore _firestore;

  CommunityRepository({required FirebaseFirestore firestore})
      : _firestore = firestore;

  CollectionReference get _postsRef => _firestore.collection('community_posts');
  CollectionReference get _groupsRef =>
      _firestore.collection('community_groups');

  // ─── Posts ─────────────────────────────────────────────────────────────────

  /// Watch all posts in the general feed (no groupId) ordered by newest first.
  Stream<List<CommunityPost>> watchFeedPosts() {
    return _postsRef
        .where('groupId', isNull: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CommunityPost.fromDocument(d)).toList());
  }

  /// Watch posts within a specific group.
  Stream<List<CommunityPost>> watchGroupPosts(String groupId) {
    return _postsRef
        .where('groupId', isEqualTo: groupId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CommunityPost.fromDocument(d)).toList());
  }

  /// Create a new post.
  Future<void> createPost(CommunityPost post) async {
    await _postsRef.doc(post.postId).set(post.toMap());
    // If post belongs to a group, increment its postCount.
    if (post.groupId != null) {
      await _groupsRef.doc(post.groupId).update({
        'postCount': FieldValue.increment(1),
      });
    }
  }

  /// Toggle like on a post.
  Future<void> togglePostLike(String postId, String userId) async {
    final doc = _postsRef.doc(postId);
    final snap = await doc.get();
    if (!snap.exists) return;
    final post = CommunityPost.fromDocument(snap);
    if (post.likedBy.contains(userId)) {
      await doc.update({
        'likedBy': FieldValue.arrayRemove([userId]),
      });
    } else {
      await doc.update({
        'likedBy': FieldValue.arrayUnion([userId]),
      });
    }
  }

  /// Delete a post.
  Future<void> deletePost(String postId) async {
    // Delete all comments for this post
    final commentsSnap = await _postsRef
        .doc(postId)
        .collection('comments')
        .get();
    for (final doc in commentsSnap.docs) {
      await doc.reference.delete();
    }
    await _postsRef.doc(postId).delete();
  }

  // ─── Comments ──────────────────────────────────────────────────────────────

  /// Watch comments for a post.
  Stream<List<Comment>> watchComments(String postId) {
    return _postsRef
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Comment.fromDocument(d)).toList());
  }

  /// Add a comment to a post.
  Future<void> addComment(Comment comment) async {
    await _postsRef
        .doc(comment.postId)
        .collection('comments')
        .doc(comment.commentId)
        .set(comment.toMap());
    // Increment comment count on the post
    await _postsRef.doc(comment.postId).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  /// Toggle like on a comment.
  Future<void> toggleCommentLike(
      String postId, String commentId, String userId) async {
    final doc =
        _postsRef.doc(postId).collection('comments').doc(commentId);
    final snap = await doc.get();
    if (!snap.exists) return;
    final comment = Comment.fromDocument(snap);
    if (comment.likedBy.contains(userId)) {
      await doc.update({
        'likedBy': FieldValue.arrayRemove([userId]),
      });
    } else {
      await doc.update({
        'likedBy': FieldValue.arrayUnion([userId]),
      });
    }
  }

  // ─── Groups ────────────────────────────────────────────────────────────────

  /// Watch all community groups.
  Stream<List<CommunityGroup>> watchAllGroups() {
    return _groupsRef
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => CommunityGroup.fromDocument(d)).toList());
  }

  /// Create a new group.
  Future<void> createGroup(CommunityGroup group) async {
    await _groupsRef.doc(group.groupId).set(group.toMap());
  }

  /// Join a group.
  Future<void> joinGroup(String groupId, String userId) async {
    await _groupsRef.doc(groupId).update({
      'memberIds': FieldValue.arrayUnion([userId]),
    });
  }

  /// Leave a group.
  Future<void> leaveGroup(String groupId, String userId) async {
    await _groupsRef.doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([userId]),
    });
  }

  /// Get a single group by id.
  Future<CommunityGroup?> getGroup(String groupId) async {
    final doc = await _groupsRef.doc(groupId).get();
    if (!doc.exists) return null;
    return CommunityGroup.fromDocument(doc);
  }
}
