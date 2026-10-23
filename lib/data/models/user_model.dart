enum UserRole {
  farmer,
  owner,
}

class UserModel {
  final String id;
  final String name;
  final String phone;
  final String password;
  final UserRole role;
  final String avatarUrl;

  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.password,
    required this.role,
    this.avatarUrl = '',
  });

  bool get isFarmer => role == UserRole.farmer;
  bool get isOwner => role == UserRole.owner;
}
