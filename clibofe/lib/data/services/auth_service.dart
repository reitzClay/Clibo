import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthService {
  // Web Client ID from Google Cloud Console
  static const String webClientId =
      '277710406862-m9kf0s96pq1t5dabdes4nsbr1hhd2j5g.apps.googleusercontent.com';

  // Base URL for Spring Boot backend
  // In development Android emulator, 10.0.2.2 points to host localhost:8080
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_URL',
    defaultValue: 'https://clibobe-277710406862.europe-west4.run.app/api/v1',
  );

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    serverClientId: webClientId,
  );

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  static const String _keyAuthToken = 'clibo_auth_token';
  static const String _keyUserEmail = 'clibo_user_email';
  static const String _keyUserName = 'clibo_user_name';

  /// Attempts silent sign-in if user has signed in before on this device
  Future<bool> trySilentSignIn() async {
    try {
      final String? savedToken = await _storage.read(key: _keyAuthToken);
      if (savedToken != null && savedToken.isNotEmpty) {
        // Try silent Google re-authentication to refresh Google ID token if needed
        final GoogleSignInAccount? account =
        await _googleSignIn.signInSilently();
        if (account != null) {
          final GoogleSignInAuthentication auth = await account.authentication;
          if (auth.idToken != null) {
            await sendTokenToBackend(auth.idToken!);
            return true;
          }
        }
        return true; // Already stored auth session
      }
    } catch (e) {
      debugPrint("Silent Sign-In Warning: $e");
    }
    return false;
  }

  /// Interactive Google Sign-In flow
  Future<Map<String, dynamic>?> signInWithGoogle() async {
    try {
      // Trigger Google account chooser dialog
      final GoogleSignInAccount? account = await _googleSignIn.signIn();
      if (account == null) {
        // User canceled sign-in
        return null;
      }

      final GoogleSignInAuthentication auth = await account.authentication;
      final String? idToken = auth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw Exception("Failed to retrieve Google ID Token from authentication.");
      }

      // Send Google ID Token to backend for cryptographic verification
      return await sendTokenToBackend(idToken);
    } catch (error) {
      debugPrint("Google Sign-In Error: $error");
      rethrow;
    }
  }

  /// Sends Google ID token to backend for verification and retrieves session profile
  Future<Map<String, dynamic>?> sendTokenToBackend(String idToken) async {
    final response = await http.post(
      Uri.parse('$backendBaseUrl/auth/google'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'token': idToken}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> userData = jsonDecode(response.body);

      // Save session details securely
      if (userData['email'] != null) {
        await _storage.write(key: _keyUserEmail, value: userData['email'].toString());
      }
      if (userData['name'] != null) {
        await _storage.write(key: _keyUserName, value: userData['name'].toString());
      }
      await _storage.write(key: _keyAuthToken, value: idToken);

      return userData;
    } else {
      final errorBody = jsonDecode(response.body);
      throw Exception(errorBody['error'] ?? 'Backend verification failed (${response.statusCode})');
    }
  }

  /// Signs out user from Google and clears local stored session tokens
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    await _storage.deleteAll();
  }

  Future<String?> getUserEmail() async => await _storage.read(key: _keyUserEmail);
  Future<String?> getUserName() async => await _storage.read(key: _keyUserName);
}
