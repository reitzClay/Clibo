import '../../../domain/user/user.dart';

abstract class UserRepository {
  Future<User?> getUserProfile();
  Future<void> saveUserProfile(User user);
  Future<void> clearUserProfile();
}
