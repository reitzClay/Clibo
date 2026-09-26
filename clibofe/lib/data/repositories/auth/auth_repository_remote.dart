import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

import '../../../domain/user/user.dart';
import 'auth_repository.dart';

class AuthRepositoryRemote implements AuthRepository {
  static const String webClientId =
      '277710406862-m9kf0s96pq1t5dabdes4nsbr1hhd2j5g.apps.googleusercontent.com';

  static const String baseUrl = 'http://10.0.2.2:8080/api/v1';

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: webClientId,
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyAuthToken = 'clibo_auth_token';
  static const String _keyUserData = 'clibo_user_data';

  User? _currentUser;

  @override
  Future<User?> getCurrentUser() async {
    if (_currentUser != null) return _currentUser;
    final String? userJson = await _storage.read(key: _keyUserData);
    final String? token = await _storage.read(key: _keyAuthToken);
    if (userJson != null) {
      try {
        _currentUser = User.fromJson(jsonDecode(userJson), token: token);
        return _currentUser;
      } catch (e) {
        debugPrint("Error parsing cached user: $e");
      }
    }
    return null;
  }

  @override
  Future<bool> trySilentSignIn() async {
    try {
      final String? token = await _storage.read(key: _keyAuthToken);
      if (token != null && token.isNotEmpty) {
        final GoogleSignInAccount? account =
        await _googleSignIn.signInSilently();
        if (account != null) {
          final GoogleSignInAuthentication auth = await account.authentication;
          if (auth.idToken != null) {
            _currentUser = await _verifyGoogleTokenWithBackend(auth.idToken!);
            return _currentUser != null;
          }
        }
        _currentUser = await getCurrentUser();
        return _currentUser != null;
      }
    } catch (e) {
      debugPrint("Silent Sign-In Error: $e");
    }
    return false;
  }

  @override
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String token = data['token']?.toString() ?? '';
        _currentUser = User.fromJson(data, token: token);
        await _saveUserSession(_currentUser!, token);
        return _currentUser;
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Authentication failed (${response.statusCode})');
      }
    } catch (e) {
      debugPrint("Email Login Error: $e");
      rethrow;
    }
  }

  @override
  Future<User?> signUpWithEmail(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final String token = data['token']?.toString() ?? '';
        _currentUser = User.fromJson(data, token: token);
        await _saveUserSession(_currentUser!, token);
        return _currentUser;
      } else {
        final Map<String, dynamic> errorData = jsonDecode(response.body);
        throw Exception(errorData['error'] ?? 'Registration failed (${response.statusCode})');
      }
    } catch (e) {
      debugPrint("Email Sign-Up Error: $e");
      rethrow;
    }
  }

  @override
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        return null; // User canceled
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception("Failed to obtain Google ID token");
      }

      _currentUser = await _verifyGoogleTokenWithBackend(idToken);
      return _currentUser;
    } catch (e) {
      debugPrint("Google Sign-In Error: $e");
      rethrow;
    }
  }

  Future<User?> _verifyGoogleTokenWithBackend(String idToken) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': idToken}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      final User user = User.fromJson(data, token: idToken);
      await _saveUserSession(user, idToken);
      return user;
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(errorData['error'] ?? 'Google token verification failed');
    }
  }

  Future<void> _saveUserSession(User user, String token) async {
    await _storage.write(key: _keyAuthToken, value: token);
    await _storage.write(key: _keyUserData, value: jsonEncode(user.toJson()));
  }

  @override
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    _currentUser = null;
    await _storage.deleteAll();
  }
}
