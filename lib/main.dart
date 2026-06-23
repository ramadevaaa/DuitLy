import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duitly/core/navigation/main_shell.dart';
import 'package:duitly/features/auth/presentation/screens/login_screen.dart';
import 'package:duitly/features/auth/presentation/providers/auth_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:duitly/core/providers/database_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await dotenv.load(fileName: ".env");
  } catch (_) {
    // Fail silently (will fallback to compile-time defines)
  }

  final container = ProviderContainer();
  final prefs = await SharedPreferences.getInstance();
  final email = prefs.getString('user_email');
  
  if (email != null) {
    final db = container.read(databaseProvider);
    final user = await db.readUserByEmail(email);
    if (user != null) {
      container.read(authProvider.notifier).setInitialUser(user);
    }
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);

    return MaterialApp(
      title: 'DuitLy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: user == null ? const LoginScreen() : MainShell(key: ValueKey(user.idUser)),
    );
  }
}
