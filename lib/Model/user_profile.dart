class UserProfile {
  final String user_id;
  final String username;
  final String? email;
  final String? role;
  final String? profilePic;
  final String? bio;
  final String? study;
  final String? location;
  final int? streakCount;
  final int? followersCount;
  final int? followingCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool? isVerified;

  UserProfile({
    required this.user_id,
    required this.username,
    this.email,
    this.role,
    this.profilePic,
    this.bio,
    this.study,
    this.location,
    this.streakCount,
    this.followersCount,
    this.followingCount,
    this.createdAt,
    this.updatedAt,
    this.isVerified,
  });


  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      user_id: json['user_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'],
      role: json['role'],
      profilePic: json['profile_pic'],
      bio: json['bio'],
      study: json['study'],
      location: json['location'],
      streakCount: json['streak_count'],
      followersCount: json['followers_count'],
      followingCount: json['following_count'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : null,
      isVerified: json['is_verified'],
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': user_id,
      'username': username,
      'email': email,
      'role': role,
      'profile_pic': profilePic,
      'bio': bio,
      'study': study,
      'location': location,
      'streak_count': streakCount,
      'followers_count': followersCount,
      'following_count': followingCount,
      'created_at': createdAt?.toIso8601String(),
      'is_verified': isVerified,
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  UserProfile copyWith({
    String? user_id,
    String? username,
    String? email,
    String? role,
    String? profilePic,
    String? bio,
    String? study,
    String? location,
    int? streakCount,
    int? followersCount,
    int? followingCount,
    DateTime? createdAt,
    bool? isVerified,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      user_id: user_id ?? this.user_id,
      username: username ?? this.username,
      email: email ?? this.email,
      role: role ?? this.role,
      profilePic: profilePic ?? this.profilePic,
      bio: bio ?? this.bio,
      study: study ?? this.study,
      location: location ?? this.location,
      streakCount: streakCount ?? this.streakCount,
      followersCount: followersCount ?? this.followersCount,
      followingCount: followingCount ?? this.followingCount,
      createdAt: createdAt ?? this.createdAt,
      isVerified: isVerified ?? this.isVerified,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.user_id == user_id;
  }

  @override
  int get hashCode => user_id.hashCode;

  @override
  String toString() {
    return 'UserProfile(userId: $user_id, username: $username, email: $email)';
  }
}