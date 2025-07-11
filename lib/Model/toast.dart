class Toast_feed {
  String? toast_id;
  String? user_id;
  String? profile_pic;
  String? username;
  String? content;
  String? title;
  List<String>? tags;
  String? created_at;
  int like_count;
  bool isliked;
  int comment_count;
  int share_count;
  List<Comment> commentsList;

  Toast_feed({
    required this.toast_id,
    required this.user_id,
    required this.username,
    this.profile_pic,
    this.content,
    this.title,
    this.tags,
    this.created_at,
    this.like_count = 0,
    this.isliked = false,
    this.comment_count = 0,
    this.share_count = 0,
    required this.commentsList,
  });

  factory Toast_feed.fromMap(Map<String, dynamic> data) {
    return Toast_feed(
      toast_id: data['toast_id'],
      user_id: data['user_id'],
      username: data['username'],
      profile_pic: data['profile_pic'],
      content: data['content'],
      title: data['title'],
      tags: data['tags'] != null ? List<String>.from(data['tags']) : [],
      created_at: data['created_at'],
      like_count: data['like_count'] ?? 0,
      comment_count: data['comment_count'] ?? 0,
      share_count: data['share_count'] ?? 0,
      isliked: data['isliked'] ?? false,
      commentsList: data['toast_comments'] != null
          ? (data['toast_comments'] as List)
          .map((comment) => Comment.fromMap(comment))
          .toList()
          : [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'toast_id': toast_id,
      'user_id': user_id,
      'username': username,
      'profile_pic': profile_pic,
      'content': content,
      'title': title,
      'tags': tags,
      'created_at': created_at,
      'like_count': like_count,
      'comment_count': comment_count,
      'share_count': share_count,
      'isliked': isliked,
    };
  }

  // Create a copy of the toast with updated fields
  Toast_feed copyWith({
    String? toast_id,
    String? user_id,
    String? profile_pic,
    String? username,
    String? content,
    String? title,
    List<String>? tags,
    String? created_at,
    int? like_count,
    bool? isliked,
    int? comment_count,
    int? share_count,
    List<Comment>? commentsList,
  }) {
    return Toast_feed(
      toast_id: toast_id ?? this.toast_id,
      user_id: user_id ?? this.user_id,
      profile_pic: profile_pic ?? this.profile_pic,
      username: username ?? this.username,
      content: content ?? this.content,
      title: title ?? this.title,
      tags: tags ?? this.tags,
      created_at: created_at ?? this.created_at,
      like_count: like_count ?? this.like_count,
      isliked: isliked ?? this.isliked,
      comment_count: comment_count ?? this.comment_count,
      share_count: share_count ?? this.share_count,
      commentsList: commentsList ?? this.commentsList,
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
    share_count++;
  }
}

class Comment {
  String username;
  String profileImage;
  String content;
  int likes;
  bool uliked;
  String timeAgo;

  Comment({
    required this.username,
    required this.profileImage,
    required this.content,
    this.likes = 0,
    this.uliked = false,
    required this.timeAgo,
  });

  void incrementLikes() {
    if (uliked) {
      likes = likes > 0 ? likes - 1 : 0;
      uliked = false;
    } else {
      likes++;
      uliked = true;
    }
  }

  Comment.fromMap(Map<String, dynamic> map)
      : username = map['username'] ?? '',
        profileImage = map['profileImage'] ?? 'assets/plaro_logo.png',
        content = map['content'] ?? '',
        timeAgo = map['timeAgo'] ?? '',
        likes = map['likes'] ?? 0,
        uliked = map['uliked'] ?? false;

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'profileImage': profileImage,
      'content': content,
      'timeAgo': timeAgo,
      'likes': likes,
      'uliked': uliked,
    };
  }
}