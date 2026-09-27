import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../app/service_locator.dart';
import '../../../../data/repositories/auth/auth_repository.dart';
import '../widgets/google_sign_in_button.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthRepository _authRepository = locator<AuthRepository>();

  bool _isEmailLoading = false;
  bool _isDevLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

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

  Future<void> _handleEmailSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || !email.contains('@')) {
      _showError("Please enter a valid email address.");
      return;
    }

    if (password.isEmpty || password.length < 6) {
      _showError("Password must be at least 6 characters.");
      return;
    }

    setState(() => _isEmailLoading = true);

    try {
      final user = await _authRepository.signInWithEmail(email, password);
      if (user != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showError("Login failed: ${e.toString().replaceAll('Exception: ', '')}");
    } finally {
      if (mounted) setState(() => _isEmailLoading = false);
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
              const SizedBox(height: 48),

              // 2. Subtitle Headers
              const Text(
                "Create an account",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter your email to sign up or log in",
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 3. Email Field Input
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                cursorColor: Colors.white,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "email@domain.com",
                  hintStyle: const TextStyle(color: Colors.white38),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white24, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3.1 Password Field Input
              TextField(
                controller: _passwordController,
                obscureText: true,
                cursorColor: Colors.white,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: "password",
                  hintStyle: const TextStyle(color: Colors.white38),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.06),
                  enabledBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white24, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: const BorderSide(color: Colors.white, width: 1.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Solid White "Continue" Core Button for Dark Theme
              ShadButton(
                size: ShadButtonSize.lg,
                backgroundColor: Colors.white,
                hoverBackgroundColor: Colors.white70,
                onPressed: _isEmailLoading ? null : _handleEmailSubmit,
                child: _isEmailLoading
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                )
                    : const Text(
                  "Continue",
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 24),

              // 5. Stylized Divider
              const Row(
                children: [
                  Expanded(child: Divider(color: Colors.white24)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      "or",
                      style: TextStyle(color: Colors.white54, fontSize: 14),
                    ),
                  ),
                  Expanded(child: Divider(color: Colors.white24)),
                ],
              ),
              const SizedBox(height: 24),

              // 6. Google Sign-In Button
              const GoogleSignInButton(),
              const SizedBox(height: 12),

              // 6.1 Developer Test Login Button (Bypass)
              OutlinedButton(
                onPressed: (_isEmailLoading || _isDevLoading) ? null : _handleDevTestLogin,
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

              const Spacer(flex: 2),

              // 7. Terms and Legal Visual Footer
              const Text(
                "By clicking continue, you agree to our Terms of Service\nand Privacy Policy",
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
