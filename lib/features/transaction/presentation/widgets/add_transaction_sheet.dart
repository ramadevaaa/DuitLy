import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duitly/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:duitly/features/transaction/presentation/providers/category_provider.dart';
import 'package:duitly/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:duitly/features/transaction/data/models/transaction_model.dart';
import 'package:duitly/features/auth/presentation/providers/auth_provider.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _titleController = TextEditingController();
  final _amountController = TextEditingController();
  String _type = 'OUT';
  int? _selectedWalletId;
  int? _selectedCategoryId;

  void _submit() {
    if (_titleController.text.isEmpty ||
        _amountController.text.isEmpty ||
        _selectedWalletId == null ||
        _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harap lengkapi semua data!')),
      );
      return;
    }

    final user = ref.read(authProvider);
    if (user == null) return;

    final transaction = TransactionModel(
      idUser: user.idUser!,
      idWallet: _selectedWalletId!,
      idKategori: _selectedCategoryId!,
      judulTransaksi: _titleController.text,
      nominal: double.tryParse(_amountController.text) ?? 0.0,
      jenisArusKas: _type,
      metodePembayaran: 'Cash/Transfer', // Default
      timeStamp: DateTime.now(),
    );

    ref.read(transactionProvider.notifier).addTransaction(transaction);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletProvider);
    final categories = ref.watch(categoryProvider);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Tambah Transaksi',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Judul Transaksi', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nominal (Rp)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _type,
              decoration: const InputDecoration(labelText: 'Jenis Arus Kas', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'IN', child: Text('Pemasukan (IN)')),
                DropdownMenuItem(value: 'OUT', child: Text('Pengeluaran (OUT)')),
              ],
              onChanged: (val) => setState(() => _type = val!),
            ),
            const SizedBox(height: 12),
            // Dropdown Wallet
            wallets.when(
              data: (list) => DropdownButtonFormField<int>(
                hint: const Text('Pilih Wallet'),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: list.map((w) => DropdownMenuItem(value: w.idWallet, child: Text(w.namaWallet))).toList(),
                onChanged: (val) => setState(() => _selectedWalletId = val),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Gagal memuat wallet'),
            ),
            const SizedBox(height: 12),
            // Dropdown Kategori
            categories.when(
              data: (list) => DropdownButtonFormField<int>(
                hint: const Text('Pilih Kategori'),
                decoration: const InputDecoration(border: OutlineInputBorder()),
                items: list
                    .where((c) => c.jenisArusKas == _type)
                    .map((c) => DropdownMenuItem(value: c.idKategori, child: Text(c.namaKategori)))
                    .toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (_, __) => const Text('Gagal memuat kategori'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Simpan Transaksi'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
