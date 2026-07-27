import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'config/theme.dart';
import 'config/routes.dart';
import 'providers/auth_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  runApp(const ProviderScope(child: GokulamApp()));
}

class GokulamApp extends ConsumerStatefulWidget {
  const GokulamApp({super.key});

  @override
  ConsumerState<GokulamApp> createState() => _GokulamAppState();
}

class _GokulamAppState extends ConsumerState<GokulamApp> {
  @override
  void initState() {
    super.initState();
    ref.read(authProvider.notifier).checkLoginStatus();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    return MaterialApp.router(
      title: 'Gokulam Traders',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
