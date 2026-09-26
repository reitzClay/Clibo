import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../domain/user/user.dart';
import 'user_repository.dart';

class UserRepositoryLocal implements UserRepository {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _keyUser = 'clibo_cached_user';

  @override
  Future<User?> getUserProfile() async {
    final String? data = await _storage.read(key: _keyUser);
    if (data == null || data.isEmpty) return null;
    try {
      return User.fromJson(jsonDecode(data));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveUserProfile(User user) async {
    await _storage.write(key: _keyUser, value: jsonEncode(user.toJson()));
  }

  @override
  Future<void> clearUserProfile() async {
    await _storage.delete(key: _keyUser);
  }
}
