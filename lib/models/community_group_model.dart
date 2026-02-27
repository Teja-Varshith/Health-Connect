import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityGroup {
  final String groupId;
  final String name;
  final String description;
  final String? iconEmoji; // Emoji icon for the group
  final String createdBy;
  final List<String> memberIds;
  final int postCount;
  final DateTime? createdAt;

  const CommunityGroup({
    required this.groupId,
    required this.name,
    required this.description,
    this.iconEmoji,
    required this.createdBy,
    this.memberIds = const [],
    this.postCount = 0,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'name': name,
      'description': description,
      'iconEmoji': iconEmoji,
      'createdBy': createdBy,
      'memberIds': memberIds,
      'postCount': postCount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory CommunityGroup.fromMap(Map<String, dynamic> map) {
    return CommunityGroup(
      groupId: map['groupId'] as String,
      name: map['name'] as String,
      description: map['description'] as String? ?? '',
      iconEmoji: map['iconEmoji'] as String?,
      createdBy: map['createdBy'] as String,
      memberIds: List<String>.from(map['memberIds'] ?? []),
      postCount: map['postCount'] as int? ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory CommunityGroup.fromDocument(DocumentSnapshot doc) =>
      CommunityGroup.fromMap(doc.data() as Map<String, dynamic>);

  CommunityGroup copyWith({
    String? groupId,
    String? name,
    String? description,
    String? iconEmoji,
    String? createdBy,
    List<String>? memberIds,
    int? postCount,
    DateTime? createdAt,
  }) {
    return CommunityGroup(
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      description: description ?? this.description,
      iconEmoji: iconEmoji ?? this.iconEmoji,
      createdBy: createdBy ?? this.createdBy,
      memberIds: memberIds ?? this.memberIds,
      postCount: postCount ?? this.postCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
