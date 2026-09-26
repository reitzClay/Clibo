import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../app/service_locator.dart';
import '../../../../data/repositories/auth/auth_repository.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final AuthRepository _authRepository = locator<AuthRepository>();

  @override
  void initState() {
    super.initState();
    _checkBootStatus();
  }

  Future<void> _checkBootStatus() async {
    final startTime = DateTime.now();

    bool isAuthenticated = false;
    try {
      isAuthenticated = await _authRepository.trySilentSignIn();
    } catch (_) {
      isAuthenticated = false;
    }

    final elapsed = DateTime.now().difference(startTime);
    if (elapsed.inMilliseconds < 1500) {
      await Future.delayed(Duration(milliseconds: 1500 - elapsed.inMilliseconds));
    }

    if (!mounted) return;

    if (isAuthenticated) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              LucideIcons.terminal,
              size: 80,
              color: Colors.black,
            ),
            SizedBox(height: 24),
            Text(
              "Initializing Clibo Engine...",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
            SizedBox(height: 32),
            CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
          ],
        ),
      ),
    );
  }
}
