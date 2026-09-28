import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../domain/user/user.dart';
import 'user_repository.dart';

class UserRepositoryRemote implements UserRepository {
  static const String baseUrl = 'http://localhost:8080/api/v1';

  @override
  Future<User?> getUserProfile() async {
    // Fetches user profile from backend
    try {
      final response = await http.get(Uri.parse('$baseUrl/user/me'));
      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }
    } catch (_) {}
    return null;
  }

  @override
  Future<void> saveUserProfile(User user) async {
    try {
      await http.put(
        Uri.parse('$baseUrl/user/me'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(user.toJson()),
      );
    } catch (_) {}
  }

  @override
  Future<void> clearUserProfile() async {}
}
