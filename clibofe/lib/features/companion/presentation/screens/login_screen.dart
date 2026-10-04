import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../../app/service_locator.dart';
import '../../../../data/repositories/auth/auth_repository.dart';
import '../widgets/google_sign_in_button.dart';
import 'home_screen.dart';
import 'register_organization_screen.dart';
import 'terms_of_service_screen.dart';
import 'privacy_policy_screen.dart';

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

  void _showConsentAndProceed(VoidCallback onConfirmed) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.grey.shade900,
          title: const Text("Terms & Privacy Notice", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "By signing in, you agree to our Terms of Service and Privacy Policy operated by ClayBytes (https://claybytes.nl/).",
                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 12),
              const Text(
                "You acknowledge that chat interactions and usage metrics are securely logged for safety, auditing, and legal compliance.",
                style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.4),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                      );
                    },
                    child: const Text("View Terms", style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                      );
                    },
                    child: const Text("View Privacy", style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
              onPressed: () async {
                Navigator.of(context).pop(); // close dialog
                try {
                  await _authRepository.logConsent("v1.0");
                } catch (_) {}
                onConfirmed();
              },
              child: const Text("I Agree & Continue", style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handleDevTestLogin() async {
    _showConsentAndProceed(() async {
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
    });
  }

  void _showCompanyLoginDialog() {
    _showConsentAndProceed(() {
      final TextEditingController emailController = TextEditingController();
      bool isDialogLoading = false;

      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setDialogState) {
              return AlertDialog(
                backgroundColor: Colors.grey.shade900,
                title: const Text("Company Login", style: TextStyle(color: Colors.white)),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      "Enter your company or organization email (e.g., admin@acme.com) to sign in.",
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: emailController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        hintText: "admin@acme.com",
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: Colors.white10,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: isDialogLoading ? null : () => Navigator.of(context).pop(),
                    child: const Text("Cancel", style: TextStyle(color: Colors.white60)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent),
                    onPressed: isDialogLoading
                        ? null
                        : () async {
                            final email = emailController.text.trim();
                            if (email.isEmpty || !email.contains('@')) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Please enter a valid email address")),
                              );
                              return;
                            }

                            setDialogState(() => isDialogLoading = true);
                            try {
                              final user = await _authRepository.signInWithEmail(email, '');
                              if (user != null && mounted) {
                                Navigator.of(context).pop(); // close dialog
                                Navigator.of(context).pushReplacement(
                                  MaterialPageRoute(builder: (_) => const HomeScreen()),
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Company login failed: ${e.toString().replaceAll('Exception: ', '')}"),
                                    backgroundColor: Colors.red.shade800,
                                  ),
                                );
                              }
                            } finally {
                              if (mounted) {
                                setDialogState(() => isDialogLoading = false);
                              }
                            }
                          },
                    child: isDialogLoading
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text("Sign In", style: TextStyle(color: Colors.white)),
                  ),
                ],
              );
            },
          );
        },
      );
    });
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
              GestureDetector(
                onTap: () {
                  _showConsentAndProceed(() {
                    // Google sign in action handled internally by button, but wrapped with consent check
                  });
                },
                child: AbsorbPointer(
                  child: const GoogleSignInButton(),
                ),
              ),
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

              // 5. Company Login Button
              OutlinedButton(
                onPressed: _showCompanyLoginDialog,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: BorderSide(color: Colors.blueAccent.shade400, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.business, color: Colors.blueAccent, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      "🏢 Company Login",
                      style: TextStyle(
                        color: Colors.blueAccent.shade400,
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

              // 5. Terms and Legal Visual Footer with Clickable Links
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(color: Colors.white38, fontSize: 12, height: 1.5),
                  children: [
                    const TextSpan(text: "By signing in, you agree to our "),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
                          );
                        },
                        child: const Text(
                          "Terms of Service",
                          style: TextStyle(color: Colors.blueAccent, fontSize: 12, decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                    const TextSpan(text: "\nand "),
                    WidgetSpan(
                      child: GestureDetector(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                          );
                        },
                        child: const Text(
                          "Privacy Policy",
                          style: TextStyle(color: Colors.blueAccent, fontSize: 12, decoration: TextDecoration.underline),
                        ),
                      ),
                    ),
                    const TextSpan(text: " (ClayBytes)"),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
