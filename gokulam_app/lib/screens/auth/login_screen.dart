import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../providers/auth_provider.dart';
import '../../config/theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    if (!_formKey.currentState!.validate()) return;
    ref.read(authProvider.notifier).login(
      _usernameController.text.trim(),
      _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final size = MediaQuery.of(context).size;

    ref.listen(authProvider, (prev, next) {
      if (next.isLoggedIn && next.user != null) {
        final role = next.user!.role;
        if (role == 'admin') context.go('/admin');
        else if (role == 'cashier') context.go('/billing');
        else if (role == 'delivery') context.go('/delivery');
        else context.go('/home');
      }
    });

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.heroGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                SizedBox(
                  height: size.height * 0.32,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.store, size: 56, color: Colors.white),
                        ).animate().scale(duration: 400.ms),
                        const SizedBox(height: 16),
                        const Text('GOKULAM', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 4)),
                        const SizedBox(height: 4),
                        Text('TRADERS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white.withAlpha(180), letterSpacing: 8)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(20),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text('Hardware · Electrical · Plumbing', style: TextStyle(fontSize: 11, color: Colors.white.withAlpha(200))),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 600.ms),
                Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                  ),
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Welcome Back', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
                        const SizedBox(height: 4),
                        Text('Sign in to your account', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                        const SizedBox(height: 28),
                        TextFormField(
                          controller: _usernameController,
                          decoration: InputDecoration(
                            labelText: 'Username',
                            prefixIcon: const Icon(Icons.person_outline, color: AppTheme.primaryColor),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outline, color: AppTheme.primaryColor),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: AppTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [BoxShadow(color: AppTheme.primaryColor.withAlpha(60), blurRadius: 8, offset: const Offset(0, 4))],
                          ),
                          child: ElevatedButton(
                            onPressed: authState.isLoading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: authState.isLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
                          ),
                        ),
                        if (authState.error != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: AppTheme.errorColor.withAlpha(10), borderRadius: BorderRadius.circular(8)),
                            child: Row(children: [
                              const Icon(Icons.error_outline, color: AppTheme.errorColor, size: 20),
                              const SizedBox(width: 8),
                              Expanded(child: Text(authState.error!, style: const TextStyle(color: AppTheme.errorColor, fontSize: 13))),
                            ]),
                          ),
                        ],
                        const SizedBox(height: 24),
                        Center(
                          child: TextButton(
                            onPressed: () => context.go('/auth/register'),
                            child: RichText(text: TextSpan(
                              text: "Don't have an account? ",
                              style: const TextStyle(color: AppTheme.textSecondary),
                              children: [
                                TextSpan(text: 'Register', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                              ],
                            )),
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ).animate().slideY(begin: 0.1, duration: 500.ms, delay: 200.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
