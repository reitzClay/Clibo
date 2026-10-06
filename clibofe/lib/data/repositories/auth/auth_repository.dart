import '../../../domain/user/user.dart';

abstract class AuthRepository {
  /// Signs in with Email and Password
  Future<User?> signInWithEmail(String email, String password);

  /// Registers a new user with Email and Password
  Future<User?> signUpWithEmail(String email, String password);

  /// Registers a new organization with company details and admin user
  Future<Map<String, dynamic>> registerOrganization({
    required String name,
    required String domain,
    required String planTier,
    required String adminEmail,
    required String adminName,
  });

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

  /// Logs user consent for Terms of Service and Privacy Policy
  Future<void> logConsent(String policyVersion);
}
