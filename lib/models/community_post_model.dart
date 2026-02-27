import 'package:cloud_firestore/cloud_firestore.dart';

class CommunityPost {
  final String postId;
  final String authorId;
  final String authorName;
  final bool isAnonymous;
  final String? groupId; // null = general feed
  final String title;
  final String body;
  final String? imageUrl;
  final List<String> likedBy;
  final int commentCount;
  final DateTime? createdAt;

  const CommunityPost({
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.isAnonymous = false,
    this.groupId,
    required this.title,
    required this.body,
    this.imageUrl,
    this.likedBy = const [],
    this.commentCount = 0,
    this.createdAt,
  });

  String get displayName => isAnonymous ? 'Anonymous' : authorName;

  Map<String, dynamic> toMap() {
    return {
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'isAnonymous': isAnonymous,
      'groupId': groupId,
      'title': title,
      'body': body,
      'imageUrl': imageUrl,
      'likedBy': likedBy,
      'commentCount': commentCount,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory CommunityPost.fromMap(Map<String, dynamic> map) {
    return CommunityPost(
      postId: map['postId'] as String,
      authorId: map['authorId'] as String,
      authorName: map['authorName'] as String? ?? 'User',
      isAnonymous: map['isAnonymous'] as bool? ?? false,
      groupId: map['groupId'] as String?,
      title: map['title'] as String,
      body: map['body'] as String,
      imageUrl: map['imageUrl'] as String?,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      commentCount: map['commentCount'] as int? ?? 0,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory CommunityPost.fromDocument(DocumentSnapshot doc) =>
      CommunityPost.fromMap(doc.data() as Map<String, dynamic>);

  CommunityPost copyWith({
    String? postId,
    String? authorId,
    String? authorName,
    bool? isAnonymous,
    String? groupId,
    String? title,
    String? body,
    String? imageUrl,
    List<String>? likedBy,
    int? commentCount,
    DateTime? createdAt,
  }) {
    return CommunityPost(
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      groupId: groupId ?? this.groupId,
      title: title ?? this.title,
      body: body ?? this.body,
      imageUrl: imageUrl ?? this.imageUrl,
      likedBy: likedBy ?? this.likedBy,
      commentCount: commentCount ?? this.commentCount,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
