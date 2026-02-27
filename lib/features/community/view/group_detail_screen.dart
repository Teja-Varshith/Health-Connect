import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_connect/features/community/controller/community_controller.dart';
import 'package:health_connect/features/community/repository/community_repository.dart';
import 'package:health_connect/features/community/view/create_post_screen.dart';
import 'package:health_connect/features/community/view/post_card.dart';
import 'package:health_connect/features/community/view/post_detail_screen.dart';
import 'package:health_connect/models/community_group_model.dart';
import 'package:health_connect/providers/user_provider.dart';

const _kTeal = Color(0xFF00897B);
const _kDark = Color(0xFF1A1A2E);

class GroupDetailScreen extends ConsumerWidget {
  final CommunityGroup group;

  const GroupDetailScreen({super.key, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsync = ref.watch(groupPostsProvider(group.groupId));
    final user = ref.watch(userProvider);
    final isMember =
        user != null && group.memberIds.contains(user.uid);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 190,
            pinned: true,
            backgroundColor: _kTeal,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF00695C),
                      Color(0xFF00897B),
                      Color(0xFF00BFA5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.15),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  group.iconEmoji ?? '💬',
                                  style: const TextStyle(fontSize: 26),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    group.name,
                                    style: const TextStyle(
                                      fontSize: 21,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                      letterSpacing: -0.3,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                          Icons.people_outline_rounded,
                                          size: 14,
                                          color: Colors.white70),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${group.memberIds.length} members',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Icon(
                                          Icons.article_outlined,
                                          size: 14,
                                          color: Colors.white70),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${group.postCount} posts',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        if (group.description.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(
                            group.description,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.white70,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            actions: [
              // Join/Leave button
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () {
                    if (user == null) return;
                    if (isMember) {
                      ref
                          .read(communityRepositoryProvider)
                          .leaveGroup(group.groupId, user.uid);
                    } else {
                      ref
                          .read(communityRepositoryProvider)
                          .joinGroup(group.groupId, user.uid);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isMember
                          ? Colors.white.withOpacity(0.2)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: isMember
                          ? Border.all(color: Colors.white.withOpacity(0.3))
                          : null,
                    ),
                    child: Text(
                      isMember ? 'Joined ✓' : 'Join',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isMember ? Colors.white : _kTeal,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Posts
          postsAsync.when(
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: _kTeal),
              ),
            ),
            error: (e, _) => SliverFillRemaining(
              child: Center(
                child: Text(
                  'Could not load posts',
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
            ),
            data: (posts) {
              if (posts.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: _kTeal.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Icon(Icons.forum_outlined,
                              size: 30, color: _kTeal.withOpacity(0.4)),
                        ),
                        const SizedBox(height: 14),
                        const Text(
                          'No posts in this group yet',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: _kDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Start the conversation!',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final post = posts[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: PostCard(
                          post: post,
                          currentUserId: user?.uid ?? '',
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  PostDetailScreen(post: post),
                            ),
                          ),
                          onLike: () {
                            if (user != null) {
                              ref
                                  .read(communityRepositoryProvider)
                                  .togglePostLike(post.postId, user.uid);
                            }
                          },
                        ),
                      );
                    },
                    childCount: posts.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: isMember
          ? FloatingActionButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreatePostScreen(
                    groupId: group.groupId,
                    groupName: group.name,
                  ),
                ),
              ),
              elevation: 3,
              backgroundColor: _kTeal,
              child: const Icon(Icons.edit_rounded, color: Colors.white, size: 22),
            )
          : null,
    );
  }
}
