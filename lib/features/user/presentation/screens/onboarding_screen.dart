import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duitly/features/user/data/models/user_model.dart';
import 'package:duitly/features/wallet/data/models/wallet_model.dart';
import 'package:duitly/core/providers/database_provider.dart';
import 'package:duitly/core/utils/password_utils.dart';
import 'package:duitly/features/auth/presentation/providers/auth_provider.dart';

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
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Halo, ${widget.nama}!',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Mari profiling sebentar agar AI bisa memberikan saran yang tepat untukmu.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              TextField(
                controller: _goalController,
                decoration: const InputDecoration(
                  labelText: 'Tujuan Finansial (Contoh: Beli Rumah, Nikah)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _incomeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Kisaran Pendapatan Per Bulan (Rp)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _initialBalanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Saldo Awal Saat Ini (Rp)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Mulai Gunakan DuitLy', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
