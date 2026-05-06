import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duitly/features/auth/presentation/providers/auth_provider.dart';
import 'package:duitly/features/user/presentation/providers/user_provider.dart';
import 'package:duitly/core/providers/database_provider.dart';
import 'package:duitly/features/auth/presentation/screens/register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _login() async {
    final db = ref.read(databaseProvider);
    final user = await db.readUserByEmail(_emailController.text);

    if (user != null) {
      if (_passwordController.text == user.password) {
        ref.read(authProvider.notifier).login(user);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email atau Password salah!')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Akun Tidak Ditemukan!')));
    }
  }

  void _forgotPassword() {
    showDialog(
      context: context,
      builder: (ctx) {
        final emailCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Lupa Password?'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Masukkan email untuk mereset password.'),
              const SizedBox(height: 12),
              TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder())),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _resetPasswordDialog(emailCtrl.text);
              },
              child: const Text('Kirim'),
            ),
          ],
        );
      }
    );
  }

  void _resetPasswordDialog(String email) {
    // Simulasi ganti password
    showDialog(
      context: context,
      builder: (ctx) {
        final passCtrl = TextEditingController();
        return AlertDialog(
          title: const Text('Reset Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Pesan reset telah dikirim (simulasi). Masukkan password baru untuk email $email'),
              const SizedBox(height: 12),
              TextField(controller: passCtrl, decoration: const InputDecoration(labelText: 'Password Baru', border: OutlineInputBorder()), obscureText: true),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () async {
                final db = ref.read(databaseProvider);
                final user = await db.readUserByEmail(email);
                if (user != null) {
                  final updatedUser = user.copyWith(password: passCtrl.text);
                  await db.updateUser(updatedUser);
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah')));
                } else {
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email tidak ditemukan!')));
                }
              },
              child: const Text('Simpan Password Baru'),
            ),
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Login', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              const SizedBox(height: 40),
              TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email', border: OutlineInputBorder()), keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 16),
              TextField(controller: _passwordController, decoration: const InputDecoration(labelText: 'Password', border: OutlineInputBorder()), obscureText: true),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(onPressed: _forgotPassword, child: const Text('Lupa Password?')),
              ),
              const SizedBox(height: 24),
              ElevatedButton(onPressed: _login, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)), child: const Text('Masuk', style: TextStyle(fontSize: 16))),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                },
                child: const Text('Belum punya akun? Buat akun'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
