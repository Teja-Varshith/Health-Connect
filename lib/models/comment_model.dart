import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String commentId;
  final String postId;
  final String authorId;
  final String authorName;
  final bool isAnonymous;
  final String body;
  final List<String> likedBy;
  final DateTime? createdAt;

  const Comment({
    required this.commentId,
    required this.postId,
    required this.authorId,
    required this.authorName,
    this.isAnonymous = false,
    required this.body,
    this.likedBy = const [],
    this.createdAt,
  });

  String get displayName => isAnonymous ? 'Anonymous' : authorName;

  Map<String, dynamic> toMap() {
    return {
      'commentId': commentId,
      'postId': postId,
      'authorId': authorId,
      'authorName': authorName,
      'isAnonymous': isAnonymous,
      'body': body,
      'likedBy': likedBy,
      'createdAt': FieldValue.serverTimestamp(),
    };
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      commentId: map['commentId'] as String,
      postId: map['postId'] as String,
      authorId: map['authorId'] as String,
      authorName: map['authorName'] as String? ?? 'User',
      isAnonymous: map['isAnonymous'] as bool? ?? false,
      body: map['body'] as String,
      likedBy: List<String>.from(map['likedBy'] ?? []),
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
    );
  }

  factory Comment.fromDocument(DocumentSnapshot doc) =>
      Comment.fromMap(doc.data() as Map<String, dynamic>);

  Comment copyWith({
    String? commentId,
    String? postId,
    String? authorId,
    String? authorName,
    bool? isAnonymous,
    String? body,
    List<String>? likedBy,
    DateTime? createdAt,
  }) {
    return Comment(
      commentId: commentId ?? this.commentId,
      postId: postId ?? this.postId,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      isAnonymous: isAnonymous ?? this.isAnonymous,
      body: body ?? this.body,
      likedBy: likedBy ?? this.likedBy,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
