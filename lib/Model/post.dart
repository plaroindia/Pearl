class Post_feed {
  String? post_id;
  String? user_id;
  String? profile_pic;
  String? username;
  String? content;
  String? caption;
  String? title;
  List<String>? tags;
  DateTime? created_at;  // Changed from String? to DateTime?
  int like_count;
  bool isliked;
  int comment_count;
  int? share_count;  // Made nullable to match usage
  List<Comment> commentsList;
  List<String>? media_urls;  // Added missing media_urls property

  Post_feed({
    required this.post_id,
    required this.user_id,
    required this.username,
    this.profile_pic,
    this.content,
    this.caption,
    this.title,
    this.tags,
    this.created_at,
    this.like_count = 0,
    this.isliked = false,
    this.comment_count = 0,
    this.share_count = 0,
    required this.commentsList,
    this.media_urls,  // Added media_urls parameter
  });

  factory Post_feed.fromMap(Map<String, dynamic> data) {
    return Post_feed(
      post_id: data['post_id'],
      user_id: data['user_id'],
      username: data['username'],
      profile_pic: data['profile_pic'],
      content: data['content'],
      caption: data['caption'],
      title: data['title'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
      created_at: data['created_at'] != null
          ? DateTime.parse(data['created_at'])
          : null,  // Parse string to DateTime
      like_count: data['like_count'] ?? 0,
      comment_count: data['comment_count'] ?? 0,
      share_count: data['share_count'] ?? 0,
      isliked: data['isliked'] ?? false,
      media_urls: data['media_urls'] != null
          ? List<String>.from(data['media_urls'])
          : null,  // Added media_urls parsing
      commentsList: data['toast_comments'] != null
          ? (data['toast_comments'] as List)
          .map((comment) => Comment.fromMap(comment))
          .toList()
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'toast_id': post_id,
      'user_id': user_id,
      'username': username,
      'profile_pic': profile_pic,
      'content': content,
      'caption': caption,
      'title': title,
      'tags': tags,
      'created_at': created_at?.toIso8601String(),  // Convert DateTime to string
      'like_count': like_count,
      'comment_count': comment_count,
      'share_count': share_count,
      'isliked': isliked,
      'media_urls': media_urls,  // Added media_urls to map
    };
  }

  // Create a copy of the toast with updated fields
  Post_feed copyWith({
    String? post_id,
    String? user_id,
    String? profile_pic,
    String? username,
    String? content,
    String? caption,
    String? title,
    List<String>? tags,
    DateTime? created_at,  // Changed to DateTime?
    int? like_count,
    bool? isliked,
    int? comment_count,
    int? share_count,
    List<Comment>? commentsList,
    List<String>? media_urls,  // Added media_urls parameter
  }) {
    return Post_feed(
      post_id: post_id ?? this.post_id,
      user_id: user_id ?? this.user_id,
      profile_pic: profile_pic ?? this.profile_pic,
      username: username ?? this.username,
      content: content ?? this.content,
      caption: caption ?? this.caption,
      title: title ?? this.title,
      tags: tags ?? this.tags,
      created_at: created_at ?? this.created_at,
      like_count: like_count ?? this.like_count,
      isliked: isliked ?? this.isliked,
      comment_count: comment_count ?? this.comment_count,
      share_count: share_count ?? this.share_count,
      commentsList: commentsList ?? this.commentsList,
      media_urls: media_urls ?? this.media_urls,  // Added media_urls
    );
  }

  // Toggle like state (used for optimistic updates)
  void toggleLike() {
    if (isliked) {
      like_count = like_count > 0 ? like_count - 1 : 0;
      isliked = false;
    } else {
      like_count++;
      isliked = true;
    }
  }

  // Increment like count (legacy method - prefer using copyWith)
  void incrementLikes() {
    if (isliked) {
      like_count = like_count > 0 ? like_count - 1 : 0;
      isliked = false;
    } else {
      like_count++;
      isliked = true;
    }
  }

  // Decrement like count
  void decrementLikes() {
    if (like_count > 0) {
      like_count--;
    }
    isliked = false;
  }

  void incrementComments() {
    comment_count++;
  }

  void incrementShares() {
    share_count = (share_count ?? 0) + 1;  // Handle nullable share_count
  }
}

class Comment {
  final int commentId;
  final String toastId;
  final String userId;
  final String username;
  final String profileImage;
  final String content;
  int likes;
  bool isliked;
  final DateTime createdAt;

  Comment({
    required this.commentId,
    required this.toastId,
    required this.userId,
    required this.username,
    required this.profileImage,
    required this.content,
    this.likes = 0,
    this.isliked = false,
    required this.createdAt,
  });

  String get timeAgo => _formatTimeAgo(createdAt);

  void toggleLike() {
    if (isliked) {
      likes = likes > 0 ? likes - 1 : 0;
      isliked = false;
    } else {
      likes++;
      isliked = true;
    }
  }

  factory Comment.fromMap(Map<String, dynamic> map) {
    return Comment(
      commentId: map['comment_id'] ?? 0,
      toastId: map['toast_id'] ?? '',
      userId: map['user_id'] ?? '',
      username: map['username'] ?? 'Unknown User',
      profileImage: map['profile_pic'] ?? 'assets/plaro_logo.png',
      content: map['content'] ?? '',
      likes: map['like_count'] ?? 0,
      isliked: map['isliked'] ?? false,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'comment_id': commentId,
      'toast_id': toastId,
      'user_id': userId,
      'username': username,
      'profile_pic': profileImage,
      'content': content,
      'like_count': likes,
      'isliked': isliked,
      'created_at': createdAt.toIso8601String(),
    };
  }

  static String _formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
  }
}