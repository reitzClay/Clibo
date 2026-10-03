import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../app/service_locator.dart';
import '../../../../data/repositories/auth/auth_repository.dart';
import '../widgets/google_sign_in_button.dart';
import 'home_screen.dart';
import 'register_organization_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthRepository _authRepository = locator<AuthRepository>();
  bool _isDevLoading = false;

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _handleDevTestLogin() async {
    setState(() => _isDevLoading = true);

    try {
      final user = await _authRepository.signInAsDevTestUser();
      if (user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showError("Dev Login failed: ${e.toString().replaceAll('Exception: ', '')}");
    } finally {
      if (mounted) setState(() => _isDevLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(flex: 2),

              // 1. App Title Branding Section
              Text(
                "Clibo AI",
                style: theme.textTheme.h1.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 32,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // 2. Subtitle Headers
              const Text(
                "Welcome to Clibo AI Companion",
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 1),

              // 3. Google Sign-In Button
              const GoogleSignInButton(),
              const SizedBox(height: 16),

              // 4. Developer Test Login Button (Bypass)
              OutlinedButton(
                onPressed: _isDevLoading ? null : _handleDevTestLogin,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: Colors.greenAccent.shade400, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: _isDevLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.greenAccent),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.flash_on, color: Colors.greenAccent, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            "🚀 Dev Test Login (Bypass)",
                            style: TextStyle(
                              color: Colors.greenAccent.shade400,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterOrganizationScreen()),
                  );
                },
                child: const Text(
                  "Register Company / Organization",
                  style: TextStyle(color: Colors.blueAccent, fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),

              const Spacer(flex: 2),

              // 5. Terms and Legal Visual Footer
              const Text(
                "By signing in, you agree to our Terms of Service\nand Privacy Policy",
                style: TextStyle(color: Colors.white38, fontSize: 12, height: 1.5),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
