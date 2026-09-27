import 'package:flutter/material.dart';
import '../../../../app/service_locator.dart';
import '../../../../data/repositories/auth/auth_repository.dart';
import '../screens/home_screen.dart';

class GoogleSignInButton extends StatefulWidget {
  final VoidCallback? onSuccess;
  const GoogleSignInButton({super.key, this.onSuccess});

  @override
  State<GoogleSignInButton> createState() => _GoogleSignInButtonState();
}

class _GoogleSignInButtonState extends State<GoogleSignInButton> {
  final AuthRepository _authRepository = locator<AuthRepository>();
  bool _isLoading = false;

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
        foregroundColor: Colors.black87,
        side: const BorderSide(color: Colors.grey, width: 0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        minimumSize: const Size.fromHeight(48),
        padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
      ),
      onPressed: _isLoading ? null : _handleGoogleSignIn,
      child: _isLoading
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  'https://upload.wikimedia.org/wikipedia/commons/c/c1/Google_%22G%22_logo.svg',
                  height: 20.0,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.login, size: 20),
                ),
                const SizedBox(width: 12.0),
                const Text(
                  'Sign in with Google',
                  style: TextStyle(
                    fontSize: 16.0,
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
