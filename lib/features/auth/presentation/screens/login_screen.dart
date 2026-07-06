import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duitly/features/auth/presentation/providers/auth_provider.dart';
import 'package:duitly/core/providers/database_provider.dart';
import 'package:duitly/core/utils/password_utils.dart';
import 'package:duitly/features/auth/presentation/screens/register_screen.dart';

const _kPrimary = Color(0xFF1565C0);
const _kPrimaryLight = Color(0xFF1976D2);
const _kPrimaryAccent = Color(0xFF42A5F5);

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;

  void _login() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Harap isi email dan password!')));
      return;
    }

    final db = ref.read(databaseProvider);
    final user = await db.readUserByEmail(_emailController.text.trim());
    if (!mounted) return;

    if (user != null) {
      if (PasswordUtils.verifyPassword(_passwordController.text, user.password)) {
        ref.read(authProvider.notifier).login(user);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email atau Password salah!')));
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Akun Tidak Ditemukan!')));
    }
  }

  void _forgotPassword() {
    final emailCtrl = TextEditingController();
    final namaCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.lock_reset, color: Colors.orange[700], size: 24),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Lupa Password?',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Masukkan email dan nama lengkap yang terdaftar untuk verifikasi identitas Anda.',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 24),
                _StyledTextField(controller: emailCtrl, label: 'Email', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _StyledTextField(controller: namaCtrl, label: 'Nama Lengkap', icon: Icons.badge_outlined),
                const SizedBox(height: 32),
                Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kPrimary, _kPrimaryLight, _kPrimaryAccent],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: _kPrimary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () async {
                        final email = emailCtrl.text.trim();
                        final nama = namaCtrl.text.trim();

                        if (email.isEmpty || nama.isEmpty) {
                          if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Email dan nama wajib diisi!')));
                          return;
                        }

                        final db = ref.read(databaseProvider);
                        final user = await db.readUserByEmail(email);

                        if (user == null) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Email tidak ditemukan!')));
                          return;
                        }

                        if (user.nama.trim().toLowerCase() != nama.toLowerCase()) {
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nama tidak cocok dengan data terdaftar.')));
                          return;
                        }

                        if (ctx.mounted) Navigator.pop(ctx);
                        _resetPasswordDialog(email);
                      },
                      child: const Center(
                        child: Text('Verifikasi Identitas', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _resetPasswordDialog(String email) {
    final passCtrl = TextEditingController();
    final confirmPassCtrl = TextEditingController();
    bool isPassVisible1 = false;
    bool isPassVisible2 = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 5,
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(3)),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: Colors.green[50], borderRadius: BorderRadius.circular(14)),
                          child: Icon(Icons.check_circle_outline, color: Colors.green[700], size: 24),
                        ),
                        const SizedBox(width: 14),
                        const Text(
                          'Buat Password Baru',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A2E)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Identitas Anda terverifikasi ($email). Silakan buat password baru Anda.',
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    _StyledTextField(
                      controller: passCtrl,
                      label: 'Password Baru',
                      icon: Icons.lock_outline,
                      obscureText: !isPassVisible1,
                      suffixIcon: IconButton(
                        icon: Icon(isPassVisible1 ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                        onPressed: () => setState(() => isPassVisible1 = !isPassVisible1),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _StyledTextField(
                      controller: confirmPassCtrl,
                      label: 'Konfirmasi Password Baru',
                      icon: Icons.lock_outline,
                      obscureText: !isPassVisible2,
                      suffixIcon: IconButton(
                        icon: Icon(isPassVisible2 ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                        onPressed: () => setState(() => isPassVisible2 = !isPassVisible2),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [_kPrimary, _kPrimaryLight, _kPrimaryAccent]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: _kPrimary.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 5))],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(16),
                          onTap: () async {
                            if (passCtrl.text.length < 6) {
                              if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Password minimal 6 karakter!')));
                              return;
                            }
                            if (passCtrl.text != confirmPassCtrl.text) {
                              if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Password dan konfirmasi tidak cocok!')));
                              return;
                            }

                            final db = ref.read(databaseProvider);
                            final user = await db.readUserByEmail(email);
                            if (user != null) {
                              final updatedUser = user.copyWith(password: PasswordUtils.hashPassword(passCtrl.text));
                              await db.updateUser(updatedUser);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(const SnackBar(content: Text('Password berhasil diubah! Silakan login.')));
                              }
                            }
                          },
                          child: const Center(
                            child: Text('Simpan Password Baru', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Top Header Graphic ──
            Container(
              width: double.infinity,
              height: 280,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kPrimary, _kPrimaryLight, _kPrimaryAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
              ),
              child: SafeArea(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5), width: 2),
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: Colors.white, size: 48),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'DuitLy',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Kelola keuangan lebih mudah.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),

            // ── Form Area ──
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Masuk',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Silakan masuk ke akun Anda',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  _StyledTextField(
                    controller: _emailController,
                    label: 'Email',
                    icon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  _StyledTextField(
                    controller: _passwordController,
                    label: 'Password',
                    icon: Icons.lock_outline,
                    obscureText: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.grey),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _forgotPassword,
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(50, 30),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text('Lupa Password?', style: TextStyle(color: _kPrimaryLight, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Login Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kPrimary, _kPrimaryLight, _kPrimaryAccent],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _kPrimary.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _login,
                        borderRadius: BorderRadius.circular(16),
                        child: const Center(
                          child: Text(
                            'Masuk',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Register Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('Belum punya akun? ', style: TextStyle(color: Colors.grey)),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                        },
                        child: const Text(
                          'Buat Akun',
                          style: TextStyle(
                            color: _kPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StyledTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType keyboardType;
  final bool obscureText;
  final Widget? suffixIcon;

  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        prefixIcon: Icon(icon, color: _kPrimary, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.grey[50],
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: Colors.grey[200]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kPrimary, width: 2),
        ),
      ),
    );
  }
}
