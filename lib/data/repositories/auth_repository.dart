import '../models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> login(String phone, String password);
  Future<UserModel?> getCurrentUser();
}

class MockAuthRepository implements AuthRepository {
  UserModel? _currentUser;

  @override
  Future<UserModel?> login(String phone, String password) async {
    return null;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _currentUser;
  }
}
