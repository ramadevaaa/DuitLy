import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duitly/features/auth/presentation/providers/auth_provider.dart';
import 'package:duitly/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:duitly/features/transaction/presentation/providers/category_provider.dart';
import 'package:duitly/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:duitly/features/transaction/presentation/providers/receipt_parser_provider.dart';
import 'package:duitly/features/transaction/data/models/transaction_model.dart';
import 'package:duitly/features/transaction/presentation/widgets/add_transaction_sheet.dart';
import 'package:duitly/features/transaction/data/models/category_model.dart';

class ScanConfirmationDialog extends ConsumerStatefulWidget {
  final ParsedReceipt parsedReceipt;

  const ScanConfirmationDialog({super.key, required this.parsedReceipt});

  @override
  ConsumerState<ScanConfirmationDialog> createState() => _ScanConfirmationDialogState();
}

class _ScanConfirmationDialogState extends ConsumerState<ScanConfirmationDialog> {
  late final TextEditingController _merchantController;
  late final TextEditingController _totalController;
  late final TextEditingController _itemsController;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _merchantController = TextEditingController(text: widget.parsedReceipt.merchant);
    _totalController = TextEditingController(text: widget.parsedReceipt.total.toStringAsFixed(0));
    _itemsController = TextEditingController(text: widget.parsedReceipt.itemsSummary);
    _selectedCategoryId = widget.parsedReceipt.categoryId;
  }

  @override
  void dispose() {
    _merchantController.dispose();
    _totalController.dispose();
    _itemsController.dispose();
    super.dispose();
  }

  void _saveInstantly() {
    final user = ref.read(authProvider);
    if (user == null || user.idUser == null) return;

    final walletsState = ref.read(walletProvider);
    final wallets = walletsState.value ?? [];
    if (wallets.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Anda belum memiliki Dompet. Silakan tambah dompet terlebih dahulu.')),
      );
      return;
    }

    final defaultWallet = wallets.first; // Use the first wallet as default
    final totalValue = double.tryParse(_totalController.text) ?? 0.0;
    
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kategori transaksi terlebih dahulu.')),
      );
      return;
    }

    final transaction = TransactionModel(
      idUser: user.idUser!,
      idWallet: defaultWallet.idWallet!,
      idKategori: _selectedCategoryId!,
      judulTransaksi: _merchantController.text.trim().isNotEmpty
          ? _merchantController.text.trim()
          : 'Transaksi Scan Struk',
      nominal: totalValue,
      jenisArusKas: 'OUT',
      metodePembayaran: 'Cash/Transfer',
      deskripsi: _itemsController.text.trim().isNotEmpty ? _itemsController.text.trim() : null,
      timeStamp: DateTime.now(),
    );

    ref.read(transactionProvider.notifier).addTransaction(transaction);
    Navigator.pop(context); // Close dialog

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.green,
        content: Text('Berhasil menyimpan ke ${defaultWallet.namaWallet}!'),
      ),
    );
  }

  void _editDetailed() {
    Navigator.pop(context); // Close confirmation dialog

    // Open AddTransactionSheet with prefilled values
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => AddTransactionSheet(
        initialTitle: _merchantController.text,
        initialAmount: double.tryParse(_totalController.text) ?? 0.0,
        initialCategoryId: _selectedCategoryId,
        initialDescription: _itemsController.text,
        isFromScan: true,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoriesState = ref.watch(categoryProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      child: Container(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.document_scanner, color: Colors.blue),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hasil Pemindaian Struk',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Text(
                          'Konfirmasi detail transaksi di bawah ini',
                          style: TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // Form fields
              const Text('Nama Toko / Merchant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              TextField(
                controller: _merchantController,
                readOnly: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                  fillColor: Colors.grey[100],
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),

              const Text('Total Pembayaran', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              TextField(
                controller: _totalController,
                readOnly: true,
                decoration: InputDecoration(
                  prefixText: 'Rp ',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                  fillColor: Colors.grey[100],
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),

              const Text('Kategori', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              categoriesState.when(
                data: (list) {
                  final filtered = list.where((c) => c.jenisArusKas == 'OUT').toList();
                  
                  // Double check that selected category exists in filtered list
                  final isValidCategory = filtered.any((c) => c.idKategori == _selectedCategoryId);
                  if (!isValidCategory && filtered.isNotEmpty) {
                    final firstId = filtered.first.idKategori;
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedCategoryId = firstId;
                        });
                      }
                    });
                  }

                  final matchedCatName = filtered.firstWhere(
                    (c) => c.idKategori == _selectedCategoryId,
                    orElse: () => filtered.isNotEmpty 
                        ? filtered.first 
                        : CategoryModel(idKategori: -1, namaKategori: 'Belanja', jenisArusKas: 'OUT'),
                  ).namaKategori;

                  return TextFormField(
                    key: ValueKey(matchedCatName),
                    initialValue: matchedCatName,
                    readOnly: true,
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                      fillColor: Colors.grey[100],
                      filled: true,
                    ),
                  );
                },
                loading: () => const LinearProgressIndicator(),
                error: (error, stack) => const Text('Gagal memuat kategori'),
              ),
              const SizedBox(height: 12),

              const Text('Ringkasan Item / Catatan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 6),
              TextField(
                controller: _itemsController,
                maxLines: 2,
                readOnly: true,
                decoration: InputDecoration(
                  hintText: 'e.g. Belanja bulanan, Susu, Sabun',
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                  fillColor: Colors.grey[100],
                  filled: true,
                ),
              ),
              const SizedBox(height: 20),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _editDetailed,
                      child: const Text('Edit Detail'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saveInstantly,
                child: const Text('Konfirmasi & Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
