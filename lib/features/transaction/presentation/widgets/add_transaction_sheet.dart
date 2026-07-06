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

// Warna tema utama — konsisten dengan dashboard
const _kPrimary = Color(0xFF1565C0);
const _kPrimaryLight = Color(0xFF1976D2);
const _kPrimaryAccent = Color(0xFF42A5F5);

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
        SnackBar(
          content: const Text('Harap lengkapi semua data!'),
          backgroundColor: Colors.red[400],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12, bottom: 16),
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Text(
              'Pilih Sumber Foto Struk',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.camera_alt, color: _kPrimary),
              ),
              title: const Text('Ambil dari Kamera'),
              onTap: () {
                Navigator.pop(ctx);
                _processScan(context, ImageSource.camera);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.photo_library, color: _kPrimary),
              ),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _processScan(context, ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
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
      builder: (context) => Center(
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: _kPrimary.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: _kPrimary),
              SizedBox(height: 16),
              Text(
                'Sedang membaca struk...',
                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
              ),
            ],
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Scan Gagal'),
          content: Text(parserState.errorMessage!),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup', style: TextStyle(color: _kPrimary)),
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

  // ── Styled input decoration ──
  InputDecoration _inputDecoration({
    required String label,
    String? hint,
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Colors.grey[600], fontSize: 14),
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: _kPrimary, size: 20)
          : null,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    );
  }

  // ── Styled dropdown decoration ──
  InputDecoration _dropdownDecoration({String? hint, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      prefixIcon: prefixIcon != null
          ? Icon(prefixIcon, color: _kPrimary, size: 20)
          : null,
      filled: true,
      fillColor: Colors.grey[50],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallets = ref.watch(walletProvider);
    final categories = ref.watch(categoryProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Drag handle ──
            Center(
              child: Container(
                width: 42,
                height: 5,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),

            // ── Header with blue accent ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 12, 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_kPrimary, _kPrimaryAccent],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: _kPrimary.withValues(alpha: 0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.receipt_long_outlined,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tambah Transaksi',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Catat pemasukan atau pengeluaran',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!widget.isFromScan)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _showScanSourceOptions(context),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.document_scanner_outlined,
                            color: _kPrimary,
                            size: 22,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // ── Segmented toggle IN/OUT ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _type = 'OUT';
                          _selectedCategoryId = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == 'OUT' ? Colors.red[50] : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                            border: _type == 'OUT'
                                ? Border.all(color: Colors.red[300]!, width: 1.5)
                                : null,
                            boxShadow: _type == 'OUT'
                                ? [
                                    BoxShadow(
                                      color: Colors.red.withValues(alpha: 0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_downward_rounded,
                                size: 18,
                                color: _type == 'OUT' ? Colors.red[600] : Colors.grey[500],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Pengeluaran',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _type == 'OUT' ? FontWeight.w700 : FontWeight.w500,
                                  color: _type == 'OUT' ? Colors.red[700] : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() {
                          _type = 'IN';
                          _selectedCategoryId = null;
                        }),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == 'IN' ? Colors.green[50] : Colors.transparent,
                            borderRadius: BorderRadius.circular(11),
                            border: _type == 'IN'
                                ? Border.all(color: Colors.green[300]!, width: 1.5)
                                : null,
                            boxShadow: _type == 'IN'
                                ? [
                                    BoxShadow(
                                      color: Colors.green.withValues(alpha: 0.1),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.arrow_upward_rounded,
                                size: 18,
                                color: _type == 'IN' ? Colors.green[600] : Colors.grey[500],
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Pemasukan',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: _type == 'IN' ? FontWeight.w700 : FontWeight.w500,
                                  color: _type == 'IN' ? Colors.green[700] : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Form fields ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: _inputDecoration(
                      label: 'Judul / Merchant',
                      hint: 'e.g. Alfamart, Gojek',
                      prefixIcon: Icons.storefront_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration(
                      label: 'Nominal (Rp)',
                      hint: 'e.g. 50000',
                      prefixIcon: Icons.payments_outlined,
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Dropdown Wallet
                  wallets.when(
                    data: (list) {
                      if (list.isNotEmpty && _selectedWalletId == null) {
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
                        decoration: _dropdownDecoration(
                          hint: 'Pilih Wallet',
                          prefixIcon: Icons.account_balance_wallet_outlined,
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kPrimary),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        items: list.map((w) => DropdownMenuItem(
                          value: w.idWallet,
                          child: Text(w.namaWallet),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedWalletId = val),
                      );
                    },
                    loading: () => const LinearProgressIndicator(color: _kPrimary),
                    error: (_, _) => const Text('Gagal memuat wallet'),
                  ),
                  const SizedBox(height: 14),

                  // Dropdown Kategori
                  categories.when(
                    data: (list) {
                      final filtered = list.where((c) => c.jenisArusKas == _type).toList();
                      
                      final isValidCategory = filtered.any((c) => c.idKategori == _selectedCategoryId);
                      if (!isValidCategory && _selectedCategoryId != null) {
                        _selectedCategoryId = null;
                      }

                      return DropdownButtonFormField<int>(
                        key: ValueKey('category_dropdown_$_type'),
                        initialValue: _selectedCategoryId,
                        hint: const Text('Pilih Kategori'),
                        decoration: _dropdownDecoration(
                          hint: 'Pilih Kategori',
                          prefixIcon: Icons.category_outlined,
                        ),
                        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _kPrimary),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        items: filtered
                            .map((c) => DropdownMenuItem(value: c.idKategori, child: Text(c.namaKategori)))
                            .toList(),
                        onChanged: (val) => setState(() => _selectedCategoryId = val),
                      );
                    },
                    loading: () => const LinearProgressIndicator(color: _kPrimary),
                    error: (_, _) => const Text('Gagal memuat kategori'),
                  ),
                  const SizedBox(height: 14),

                  TextField(
                    controller: _descriptionController,
                    maxLines: 2,
                    decoration: _inputDecoration(
                      label: 'Deskripsi / Detail Barang',
                      hint: 'e.g. Belanja bulanan, Susu, Sabun',
                      prefixIcon: Icons.notes_outlined,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Submit button with gradient ──
                  Container(
                    width: double.infinity,
                    height: 52,
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
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                              SizedBox(width: 8),
                              Text(
                                'Simpan Transaksi',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
