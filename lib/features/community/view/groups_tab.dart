import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:health_connect/features/community/controller/community_controller.dart';
import 'package:health_connect/features/community/repository/community_repository.dart';
import 'package:health_connect/features/community/view/create_group_screen.dart';
import 'package:health_connect/features/community/view/group_detail_screen.dart';
import 'package:health_connect/models/community_group_model.dart';
import 'package:health_connect/providers/user_provider.dart';

const _kTeal = Color(0xFF00897B);
const _kDark = Color(0xFF1A1A2E);

class GroupsTab extends ConsumerWidget {
  const GroupsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(allGroupsProvider);
    final user = ref.watch(userProvider);

    return groupsAsync.when(
      loading: () =>
          const Center(child: CircularProgressIndicator(color: _kTeal)),
      error: (e, _) => Center(
        child: Text(
          'Could not load groups',
          style: TextStyle(color: Colors.grey.shade500),
        ),
      ),
      data: (groups) {
        return Column(
          children: [
            // Create group button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const CreateGroupScreen(),
                  ),
                ),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _kTeal.withOpacity(0.25),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _kTeal.withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _kTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_rounded,
                            color: _kTeal, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Create a Group',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _kDark,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Start a new community around a topic',
                              style: TextStyle(
                                fontSize: 11,
                                color: Color(0xFF78909C),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded,
                          color: Colors.grey.shade300),
                    ],
                  ),
                ),
              ),
            ),

            if (groups.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: _kTeal.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(Icons.groups_outlined,
                            size: 36, color: _kTeal.withOpacity(0.5)),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No groups yet',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: _kDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Create the first group and invite others!',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                  itemCount: groups.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final group = groups[index];
                    final isMember = user != null &&
                        group.memberIds.contains(user.uid);
                    return _groupCard(context, ref, group, user?.uid, isMember);
                  },
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _groupCard(
    BuildContext context,
    WidgetRef ref,
    CommunityGroup group,
    String? userId,
    bool isMember,
  ) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => GroupDetailScreen(group: group),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade100, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Group icon
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF00695C), Color(0xFF00897B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  group.iconEmoji ?? '💬',
                  style: const TextStyle(fontSize: 22),
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
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _kDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    group.description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.people_outline_rounded,
                          size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        '${group.memberIds.length} members',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400),
                      ),
                      const SizedBox(width: 12),
                      Icon(Icons.article_outlined,
                          size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(
                        '${group.postCount} posts',
                        style: TextStyle(
                            fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Join / Joined
            GestureDetector(
              onTap: () {
                if (userId == null) return;
                if (isMember) {
                  ref
                      .read(communityRepositoryProvider)
                      .leaveGroup(group.groupId, userId);
                } else {
                  ref
                      .read(communityRepositoryProvider)
                      .joinGroup(group.groupId, userId);
                }
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isMember ? Colors.white : _kTeal,
                  borderRadius: BorderRadius.circular(10),
                  border: isMember
                      ? Border.all(color: Colors.grey.shade300)
                      : null,
                  boxShadow: isMember
                      ? null
                      : [
                          BoxShadow(
                            color: _kTeal.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Text(
                  isMember ? 'Joined' : 'Join',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isMember ? Colors.grey.shade500 : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
