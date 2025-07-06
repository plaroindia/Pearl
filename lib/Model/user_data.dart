class User{
  String? userid;
  String username;
  String? email;
  String? password;
  String? role;
  String? purpose;

  User({
    required this.userid,
    required this.username,
    required this.email,
    required this.password,
    this.role,
    this.purpose,
  });
}