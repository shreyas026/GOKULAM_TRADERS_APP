import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../providers/auth_provider.dart';
import '../config/theme.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    ref.read(authProvider.notifier).checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.store, size: 80, color: Colors.white).animate().scale(duration: 600.ms).then().shake(),
            const SizedBox(height: 24),
            const Text('GOKULAM TRADERS', style: TextStyle(
              fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2,
            )).animate().fadeIn(duration: 800.ms).slideY(begin: 0.3),
            const SizedBox(height: 8),
            Text('Hardware, Electrical & Plumbing', style: TextStyle(
              fontSize: 14, color: Colors.white.withAlpha(200),
            )).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}