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
  Future<User?> signInWithEmail(String email, String password) async => null;

  @override
  Future<User?> signInWithGoogle() async => null;

  @override
  Future<User?> signUpWithEmail(String email, String password) async => null;

  @override
  Future<bool> trySilentSignIn() async => false;
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
