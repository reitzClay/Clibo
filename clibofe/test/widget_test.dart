import 'package:flutter_test/flutter_test.dart';
import 'package:clibofe/main.dart';
import 'package:clibofe/app/service_locator.dart';
import 'package:clibofe/data/repositories/auth/auth_repository.dart';
import 'package:clibofe/domain/user/user.dart';

class MockAuthRepository implements AuthRepository {
  @override
  Future<User?> getCurrentUser() async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<bool> deleteAccount() async => true;

  @override
  Future<User?> signInWithEmail(String email, String password) async => null;

  @override
  Future<User?> signInWithGoogle() async => null;

  @override
  Future<Map<String, dynamic>> registerOrganization({
    required String name,
    required String domain,
    required String planTier,
    required String adminEmail,
    required String adminName,
  }) async => {};

  @override
  Future<User?> signUpWithEmail(String email, String password) async => null;

  @override
  Future<bool> trySilentSignIn() async => false;

  @override
  Future<void> logConsent(String policyVersion) async {}

  @override
  Future<User?> signInAsDevTestUser() async => const User(
        id: 999,
        email: 'dev@clibo.ai',
        name: 'Developer Tester',
        userTier: 'PRO',
        systemRole: 'ADMIN',
        token: 'dev_mock_token_999',
      );
}

void main() {
  testWidgets('CliboApp smoke test', (WidgetTester tester) async {
    if (locator.isRegistered<AuthRepository>()) {
      locator.unregister<AuthRepository>();
    }
    locator.registerLazySingleton<AuthRepository>(() => MockAuthRepository());

    // Build our app and trigger a frame.
    await tester.pumpWidget(const CliboApp());
    await tester.pumpAndSettle();

    // Verify that CliboApp is present.
    expect(find.byType(CliboApp), findsOneWidget);
  });
}
