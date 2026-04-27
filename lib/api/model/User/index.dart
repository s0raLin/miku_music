class User {
  final String username;
  final String? avatarURL;

  User({required this.username, required this.avatarURL});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(username: json["username"], avatarURL: json["avatar"]);
  }
}
