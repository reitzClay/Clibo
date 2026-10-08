import 'package:flutter/material.dart';
import 'package:clibofe/app/service_locator.dart';
import 'package:clibofe/data/repositories/auth/auth_repository.dart';
import '../screens/home_screen.dart';

class GoogleSignInButton extends StatefulWidget {
  final VoidCallback? onSuccess;
  final VoidCallback? onConsentRequired;
  const GoogleSignInButton({super.key, this.onSuccess, this.onConsentRequired});

  @override
  State<GoogleSignInButton> createState() => GoogleSignInButtonState();
}

class GoogleSignInButtonState extends State<GoogleSignInButton> {
  final AuthRepository _authRepository = locator<AuthRepository>();
  bool _isLoading = false;

  Future<void> triggerSignIn() async {
    await _handleGoogleSignIn();
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = await _authRepository.signInWithGoogle();
      if (user != null && mounted) {
        if (widget.onSuccess != null) {
          widget.onSuccess!();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      }
    } catch (error) {
      debugPrint('Google Sign-In Error: $error');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign-in failed: ${error.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: Colors.red.shade800,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F1F1F),
        side: const BorderSide(color: Color(0xFF747775), width: 1.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        elevation: 0,
      ),
      onPressed: _isLoading
          ? null
          : () {
              if (widget.onConsentRequired != null) {
                widget.onConsentRequired!();
              } else {
                _handleGoogleSignIn();
              }
            },
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF1F1F1F)),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/google.png',
                  width: 22,
                  height: 22,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Roboto',
                      color: Color(0xFF4285F4),
                    ),
                  ),
                ),
                const SizedBox(width: 12.0),
                const Text(
                  'Sign in with Google',
                  style: TextStyle(
                    fontSize: 15.0,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'Roboto',
                    color: Color(0xFF1F1F1F),
                  ),
                ),
              ],
            ),
    );
  }
}
