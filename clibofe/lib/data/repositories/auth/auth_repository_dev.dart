import '../../../domain/user/user.dart';
import 'auth_repository.dart';

class AuthRepositoryDev implements AuthRepository {
  User? _mockUser;

  @override
  Future<User?> getCurrentUser() async => _mockUser;

  @override
  Future<bool> trySilentSignIn() async {
    await Future.delayed(const Duration(milliseconds: 500));
    return _mockUser != null;
  }

  @override
  Future<User?> signInWithEmail(String email, String password) async {
    await Future.delayed(const Duration(milliseconds: 800));
    _mockUser = User(
      id: 1,
      email: email,
      name: email.split('@').first,
      userTier: 'FREE',
      systemRole: 'USER',
      token: 'mock_jwt_token_123',
    );
    return _mockUser;
  }

  @override
  Future<User?> signUpWithEmail(String email, String password) async {
    return signInWithEmail(email, password);
  }

  @override
  Future<User?> signInWithGoogle() async {
    await Future.delayed(const Duration(milliseconds: 1000));
    _mockUser = const User(
      id: 2,
      email: 'clayton@clibo.ai',
      name: 'Clayton',
      userTier: 'PRO',
      systemRole: 'USER',
      token: 'mock_google_jwt_456',
    );
    return _mockUser;
  }

  @override
  Future<Map<String, dynamic>> registerOrganization({
    required String name,
    required String domain,
    required String planTier,
    required String adminEmail,
    required String adminName,
  }) async {
    await Future.delayed(const Duration(milliseconds: 800));
    return {
      'organization': {'id': 1, 'name': name, 'domainRestriction': domain, 'planTier': planTier},
      'admin': {'id': 10, 'email': adminEmail, 'name': adminName}
    };
  }

  @override
  Future<void> signOut() async {
    _mockUser = null;
  }

  @override
  Future<User?> signInAsDevTestUser() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _mockUser = const User(
      id: 999,
      email: 'dev@clibo.ai',
      name: 'Developer Tester',
      userTier: 'PRO',
      systemRole: 'ADMIN',
      token: 'dev_mock_token_999',
    );
    return _mockUser;
  }

  @override
  Future<void> logConsent(String policyVersion) async {
    await Future.delayed(const Duration(milliseconds: 200));
  }
}
