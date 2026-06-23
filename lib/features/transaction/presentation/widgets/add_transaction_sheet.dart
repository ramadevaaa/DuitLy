import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:duitly/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:duitly/features/transaction/presentation/providers/category_provider.dart';
import 'package:duitly/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:duitly/features/transaction/presentation/providers/receipt_parser_provider.dart';
import 'package:duitly/features/auth/presentation/providers/auth_provider.dart';
import 'package:duitly/features/transaction/presentation/widgets/scan_confirmation_dialog.dart';
import 'package:duitly/features/transaction/data/models/transaction_model.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  final String? initialTitle;
  final double? initialAmount;
  final int? initialCategoryId;
  final String? initialDescription;
  final bool isFromScan;

  const AddTransactionSheet({
    super.key,
    this.initialTitle,
    this.initialAmount,
    this.initialCategoryId,
    this.initialDescription,
    this.isFromScan = false,
  });

  @override
  ConsumerState<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _amountController;
  late final TextEditingController _descriptionController;
  String _type = 'OUT';
  int? _selectedWalletId;
  int? _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _amountController = TextEditingController(
      text: widget.initialAmount != null && widget.initialAmount! > 0
          ? widget.initialAmount!.toStringAsFixed(0)
          : '',
    );
    _descriptionController = TextEditingController(text: widget.initialDescription);
    _selectedCategoryId = widget.initialCategoryId;
    
    if (widget.isFromScan) {
      _type = 'OUT'; // Receipts are always expenses
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_titleController.text.trim().isEmpty ||
        _amountController.text.trim().isEmpty ||
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
      judulTransaksi: _titleController.text.trim(),
      nominal: double.tryParse(_amountController.text.trim()) ?? 0.0,
      jenisArusKas: _type,
      metodePembayaran: 'Cash/Transfer', // Default
      deskripsi: _descriptionController.text.trim().isNotEmpty 
          ? _descriptionController.text.trim() 
          : null,
      timeStamp: DateTime.now(),
    );

    ref.read(transactionProvider.notifier).addTransaction(transaction);
    Navigator.pop(context);
  }

  void _showScanSourceOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                'Pilih Sumber Foto Struk',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Ambil dari Kamera'),
              onTap: () {
                Navigator.pop(ctx);
                _processScan(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _processScan(context, ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _processScan(BuildContext context, ImageSource source) async {
    // Show non-dismissible loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Sedang membaca struk...'),
              ],
            ),
          ),
        ),
      ),
    );

    // Call parse receipt
    final parsed = await ref.read(receiptParserProvider.notifier).parseReceipt(source);
    
    if (!context.mounted) return;

    // Close loading dialog
    Navigator.pop(context); // pops loading dialog

    if (!context.mounted) return;

    final parserState = ref.read(receiptParserProvider);
    if (parserState.errorMessage != null) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Scan Gagal'),
          content: Text(parserState.errorMessage!),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } else if (parsed != null) {
      final navigator = Navigator.of(context);
      // Pop the current AddTransactionSheet first
      navigator.pop();

      final navContext = navigator.context;
      if (!navContext.mounted) return;

      // Show the ScanConfirmationDialog (Overview)
      showDialog(
        context: navContext,
        barrierDismissible: false,
        builder: (context) => ScanConfirmationDialog(parsedReceipt: parsed),
      );
    }
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
            Row(
              children: [
                const Spacer(flex: 3),
                const Text(
                  'Tambah Transaksi',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const Spacer(flex: 2),
                if (!widget.isFromScan)
                  IconButton(
                    icon: const Icon(Icons.document_scanner, color: Colors.blue),
                    tooltip: 'Scan Struk',
                    onPressed: () => _showScanSourceOptions(context),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Judul / Merchant', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Nominal (Rp)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _type,
              decoration: const InputDecoration(labelText: 'Jenis Arus Kas', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'IN', child: Text('Pemasukan (IN)')),
                DropdownMenuItem(value: 'OUT', child: Text('Pengeluaran (OUT)')),
              ],
              onChanged: (val) => setState(() {
                _type = val!;
                _selectedCategoryId = null; // Reset category selection when flow type changes
              }),
            ),
            const SizedBox(height: 12),
            // Dropdown Wallet
            wallets.when(
              data: (list) {
                if (list.isNotEmpty && _selectedWalletId == null) {
                  // Pre-select first wallet
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _selectedWalletId == null) {
                      setState(() {
                        _selectedWalletId = list.first.idWallet;
                      });
                    }
                  });
                }
                return DropdownButtonFormField<int>(
                  initialValue: _selectedWalletId,
                  hint: const Text('Pilih Wallet'),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: list.map((w) => DropdownMenuItem(value: w.idWallet, child: Text(w.namaWallet))).toList(),
                  onChanged: (val) => setState(() => _selectedWalletId = val),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('Gagal memuat wallet'),
            ),
            const SizedBox(height: 12),
            categories.when(
              data: (list) {
                final filtered = list.where((c) => c.jenisArusKas == _type).toList();
                
                // Ensure the selected category ID is valid for current type
                final isValidCategory = filtered.any((c) => c.idKategori == _selectedCategoryId);
                if (!isValidCategory && _selectedCategoryId != null) {
                  _selectedCategoryId = null;
                }

                return DropdownButtonFormField<int>(
                  key: ValueKey('category_dropdown_$_type'), // Force recreation when cash flow type changes to reset state
                  initialValue: _selectedCategoryId,
                  hint: const Text('Pilih Kategori'),
                  decoration: const InputDecoration(border: OutlineInputBorder()),
                  items: filtered
                      .map((c) => DropdownMenuItem(value: c.idKategori, child: Text(c.namaKategori)))
                      .toList(),
                  onChanged: (val) => setState(() => _selectedCategoryId = val),
                );
              },
              loading: () => const LinearProgressIndicator(),
              error: (_, _) => const Text('Gagal memuat kategori'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Deskripsi / Detail Barang',
                hintText: 'e.g. Belanja bulanan, Susu, Sabun',
                border: OutlineInputBorder(),
              ),
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
