class UserProfile {
  final String userid;
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
  final bool? isVerified;

  UserProfile({
    required this.userid,
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
    this.isVerified,
  });
}
