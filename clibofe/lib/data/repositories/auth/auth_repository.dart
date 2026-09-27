import '../../../domain/user/user.dart';

abstract class AuthRepository {
  /// Signs in with Email and Password
  Future<User?> signInWithEmail(String email, String password);

  /// Registers a new user with Email and Password
  Future<User?> signUpWithEmail(String email, String password);

  /// Signs in using Google ID Token flow
  Future<User?> signInWithGoogle();

  /// Tries silent Google authentication/stored token verification on startup
  Future<bool> trySilentSignIn();

  /// Signs out user and clears local tokens
  Future<void> signOut();

  /// Gets currently authenticated user profile
  Future<User?> getCurrentUser();

  /// Instant developer login to bypass network/OAuth during development
  Future<User?> signInAsDevTestUser();
}
