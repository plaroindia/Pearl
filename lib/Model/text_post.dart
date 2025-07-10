// models/text_post.dart
class Toast {
  final String? toast_id;
  final String user_id;
  final String title;
  final String content;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final bool isPublished;
  final int likes;
  final int commentCount;

  Toast({
    required this.toast_id,
    required this.user_id,
    required this.title,
    required this.content,
    this.tags = const [],
    required this.createdAt,
    this.updatedAt,
    this.isPublished = false,
    this.likes = 0,
    this.commentCount = 0,
  });

  Toast copyWith({
    String? toast_id,
    String? user_id,
    String? title,
    String? content,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPublished,
    int? likes,
    int? commentCount,
  }) {
    return Toast(
      toast_id: toast_id ?? this.toast_id,
      user_id: user_id ?? this.user_id,
      title: title ?? this.title,
      content: content ?? this.content,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPublished: isPublished ?? this.isPublished,
      likes: likes ?? this.likes,
      commentCount: commentCount ?? this.commentCount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'toast_id': toast_id,
      'user_id': user_id,
      'title': title,
      'content': content,
      'tags': tags,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'is_published': isPublished,
      'likes': likes,
      'comment_count': commentCount,
    };
  }

  factory Toast.fromJson(Map<String, dynamic> json) {
    return Toast(
      toast_id: json['toast_id'],
      user_id: json['user_id'],
      title: json['title'],
      content: json['content'],
      tags: List<String>.from(json['tags'] ?? []),
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
      isPublished: json['is_published'] ?? false,
      likes: json['likes'] ?? 0,
      commentCount: json['comment_count'] ?? 0,
    );
  }
}