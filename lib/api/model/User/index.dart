class User {
  final String username;
  final String? avatarURL;
  final String email;

  User({required this.username, required this.avatarURL, required this.email});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json["username"],
      avatarURL: json["avatar"],
      email: json['email'],
    );
  }
}
