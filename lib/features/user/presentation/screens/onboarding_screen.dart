import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duitly/features/user/data/models/user_model.dart';
import 'package:duitly/features/wallet/data/models/wallet_model.dart';
import 'package:duitly/core/providers/database_provider.dart';
import 'package:duitly/core/utils/password_utils.dart';
import 'package:duitly/features/auth/presentation/providers/auth_provider.dart';

const _kPrimary = Color(0xFF1565C0);
const _kPrimaryLight = Color(0xFF1976D2);
const _kPrimaryAccent = Color(0xFF42A5F5);

class OnboardingScreen extends ConsumerStatefulWidget {
  final String nama;
  final String email;
  final String password;

  const OnboardingScreen({
    super.key,
    required this.nama,
    required this.email,
    required this.password,
  });

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _goalController = TextEditingController();
  final _incomeController = TextEditingController();
  final _initialBalanceController = TextEditingController();

  void _submit() async {
    if (_goalController.text.isEmpty ||
        _incomeController.text.isEmpty ||
        _initialBalanceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap isi semua kolom!')),
      );
      return;
    }

    // Cek duplikasi email
    final db = ref.read(databaseProvider);
    final existingUser = await db.readUserByEmail(widget.email);
    if (!mounted) return;
    if (existingUser != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Email sudah terdaftar! Gunakan email lain.')),
      );
      return;
    }

    final initialBalance = double.tryParse(_initialBalanceController.text) ?? 0.0;

    final user = UserModel(
      nama: widget.nama,
      email: widget.email,
      password: PasswordUtils.hashPassword(widget.password),
      tujuanFinansial: _goalController.text,
      kisaranPendapatan: double.tryParse(_incomeController.text) ?? 0.0,
      totalKekayaan: initialBalance,
    );

    // 1. Simpan User
    final idUser = await db.insertUser(user);
    final newUser = user.copyWith(idUser: idUser);

    // 2. Buat Wallet Pertama secara otomatis
    await db.insertWallet(WalletModel(
      idUser: idUser,
      namaWallet: 'Dompet Utama',
      saldo: initialBalance,
      jenisWallet: 'Tunai',
      catatanWallet: 'Dibuat saat onboarding',
    ));

    // 3. Set auth status ke login
    ref.read(authProvider.notifier).login(newUser);

    // 4. Kembali ke halaman awal agar state main.dart mengambil alih (MainShell)
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
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
              height: 260,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kPrimary, _kPrimaryLight, _kPrimaryAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    // Back Button
                    Positioned(
                      top: 10,
                      left: 10,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    Center(
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
                            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 48),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Langkah Terakhir!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Bantu AI mengenali profil Anda.',
                            style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                          ),
                        ],
                      ),
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
                  Text(
                    'Halo, ${widget.nama}!',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Mari profiling sebentar agar AI bisa memberikan saran yang tepat untukmu.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 32),

                  _StyledTextField(
                    controller: _goalController,
                    label: 'Tujuan Finansial',
                    icon: Icons.flag_outlined,
                    hintText: 'Contoh: Beli Rumah, Nikah, dll',
                  ),
                  const SizedBox(height: 16),
                  _StyledTextField(
                    controller: _incomeController,
                    label: 'Kisaran Pendapatan (Rp)',
                    icon: Icons.payments_outlined,
                    keyboardType: TextInputType.number,
                    hintText: 'Pendapatan per bulan',
                  ),
                  const SizedBox(height: 16),
                  _StyledTextField(
                    controller: _initialBalanceController,
                    label: 'Saldo Awal Saat Ini (Rp)',
                    icon: Icons.account_balance_wallet_outlined,
                    keyboardType: TextInputType.number,
                    hintText: 'Total kekayaan / saldo saat ini',
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Submit Button
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
                        onTap: _submit,
                        borderRadius: BorderRadius.circular(16),
                        child: const Center(
                          child: Text(
                            'Mulai Gunakan DuitLy',
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
  final String? hintText;

  const _StyledTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.hintText,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
        prefixIcon: Icon(icon, color: _kPrimary, size: 20),
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
