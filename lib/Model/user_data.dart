class User{
  String? user_id;
  String username;
  String? email;
  String? password;
  String? role;
  String? purpose;

  User({
    required this.user_id,
    required this.username,
    required this.email,
    required this.password,
    this.role,
    this.purpose,
  });
}