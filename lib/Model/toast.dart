class Toast{
  String? user;
  String profilePic;
  String? ufeed;
  String? caption;
  int likes;
  bool uliked;
  int comments;
  int shares;
  List<Comment> commentsList;

  Toast({
    required this.user,
    required this.profilePic,
    required this.ufeed,
    required this.caption,
    this.likes = 0,
    this.uliked = false,
    this.comments = 0,
    this.shares = 0,
    required this.commentsList,
  });

  void incrementLikes() {
    if (uliked) {
      likes--;
      uliked = false;
    } else {
      likes++;
      uliked = true;
    }
  }

  void incrementComments() {
    comments++;
  }

  void incrementShares() {
    shares++;
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
      likes--;
      uliked = false;
    } else {
      likes++;
      uliked = true;
    }
  }


  Comment.fromMap(Map<String, dynamic> map)
      : username = map['username'] ?? '',
        profileImage = map['profileImage'] ?? 'assets/default_profile.png',
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