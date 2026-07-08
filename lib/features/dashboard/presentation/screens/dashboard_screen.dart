import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:duitly/features/user/presentation/providers/user_provider.dart';
import 'package:duitly/features/auth/presentation/providers/auth_provider.dart';
import 'package:duitly/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:duitly/features/wallet/data/models/wallet_model.dart';
import 'package:duitly/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:duitly/core/providers/database_provider.dart';
// ignore: unused_import
import 'package:duitly/features/dashboard/presentation/providers/welcome_ai_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:duitly/core/navigation/main_shell.dart';
import 'package:duitly/features/transaction/presentation/providers/receipt_parser_provider.dart';
import 'package:duitly/features/transaction/presentation/widgets/scan_confirmation_dialog.dart';
import 'package:duitly/features/transaction/presentation/widgets/add_transaction_sheet.dart';
import 'package:duitly/features/dashboard/presentation/screens/notification_screen.dart';
import 'package:duitly/features/transaction/data/models/transaction_model.dart';
import 'package:duitly/features/transaction/presentation/providers/report_pdf_service.dart';
import 'package:duitly/features/transaction/presentation/providers/category_provider.dart';
import 'package:duitly/features/transaction/data/models/category_model.dart';
import 'package:duitly/features/transaction/presentation/widgets/voice_record_sheet.dart';


// Warna tema utama
const _kPrimary = Color(0xFF1565C0);
const _kPrimaryLight = Color(0xFF1976D2);
const _kPrimaryAccent = Color(0xFF42A5F5);

class _WalletType {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _WalletType({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  int _selectedPeriodTab = 0;
  DateTime? _selectedCalendarDate;

  final List<String> _periodTabs = [
    'Minggu Lalu',
    'Bulan Lalu',
    '3 Bulan Lalu',
    'Kalender',
  ];

  void _showDailyDetailDialog(BuildContext context, DateTime date, List<TransactionModel> allTransactions, NumberFormat fmt) {
    final targetDate = DateTime(date.year, date.month, date.day);
    final dayTxs = allTransactions.where((tx) {
      final d = tx.timeStamp;
      return d.year == targetDate.year && d.month == targetDate.month && d.day == targetDate.day;
    }).toList();

    dayTxs.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));

    final categories = ref.read(categoryProvider).value ?? [];

    double dayIn = 0;
    double dayOut = 0;
    for (final tx in dayTxs) {
      if (tx.jenisArusKas == 'IN') dayIn += tx.nominal;
      if (tx.jenisArusKas == 'OUT') dayOut += tx.nominal;
    }
    double dayNet = dayIn - dayOut;

    final dateStr = DateFormat('dd MMMM yyyy').format(date);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.only(top: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle bar
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Header & PDF Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Detail Harian', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 2),
                        Text(dateStr, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
                      ],
                    ),
                    if (dayTxs.isNotEmpty)
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange[600],
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          minimumSize: Size.zero,
                        ),
                        icon: const Icon(Icons.picture_as_pdf_outlined, size: 14),
                        label: const Text('PDF', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        onPressed: () {
                          final user = ref.read(authProvider);
                          ReportPdfService.generateAndPrint(
                            dayTxs,
                            user?.nama ?? 'User',
                            'Harian ($dateStr)',
                          );
                        },
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Summary
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey[200]!),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.arrow_upward, size: 14, color: Colors.green),
                              const SizedBox(width: 4),
                              Text('Pemasukan', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            ],
                          ),
                          Text(fmt.format(dayIn), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.green)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.arrow_downward, size: 14, color: Colors.red),
                              const SizedBox(width: 4),
                              Text('Pengeluaran', style: TextStyle(fontSize: 11, color: Colors.grey[600])),
                            ],
                          ),
                          Text(fmt.format(dayOut), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red)),
                        ],
                      ),
                      const Divider(height: 16, thickness: 1),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Selisih Bersih', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[700])),
                          Text(
                            '${dayNet >= 0 ? "+" : ""}${fmt.format(dayNet)}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: dayNet >= 0 ? Colors.green[700] : Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Transaction List
              Flexible(
                child: dayTxs.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'Tidak ada transaksi pada hari ini.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: dayTxs.length,
                        itemBuilder: (context, index) {
                          final tx = dayTxs[index];
                          final isOut = tx.jenisArusKas == 'OUT';
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey[200]!),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: isOut ? Colors.red[50] : Colors.green[50],
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    isOut ? Icons.arrow_downward : Icons.arrow_upward,
                                    color: isOut ? Colors.red[400] : Colors.green[600],
                                    size: 14,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.judulTransaksi,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 5,
                                              vertical: 1.5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isOut ? Colors.red[50] : Colors.green[50],
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              (() {
                                                final cat = categories.firstWhere(
                                                  (c) => c.idKategori == tx.idKategori,
                                                  orElse: () => CategoryModel(
                                                    namaKategori: 'Lainnya',
                                                    jenisArusKas: '',
                                                  ),
                                                );
                                                return cat.namaKategori;
                                              })(),
                                              style: TextStyle(
                                                fontSize: 9,
                                                fontWeight: FontWeight.w600,
                                                color: isOut ? Colors.red[600] : Colors.green[700],
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            DateFormat('HH:mm').format(tx.timeStamp),
                                            style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  '${isOut ? "-" : "+"}${fmt.format(tx.nominal)}',
                                  style: TextStyle(
                                    color: isOut ? Colors.red[400] : Colors.green[600],
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }


  Future<void> _selectCalendarDate(BuildContext _, List<TransactionModel> allTransactions, NumberFormat fmt) async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedCalendarDate ?? now,
      firstDate: DateTime(2020),
      lastDate: DateTime(now.year + 2),
      builder: (ctx, child) {
        return Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _kPrimary,
              onPrimary: Colors.white,
              onSurface: Colors.black87,
            ),
          ),
          child: child!,
        );
      },
    );
    if (!mounted || pickedDate == null) return;
    _selectedCalendarDate = pickedDate;
    final freshTxs = ref.read(transactionProvider).value ?? allTransactions;
    _showDailyDetailDialog(context, pickedDate, freshTxs, fmt);
  }

  @override
  void dispose() {
    super.dispose();
  }

  // ── Dialog tambah wallet ──────────────────────────────────────────────
  void _showAddWalletDialog(BuildContext context) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String jenisWallet = 'Cash';
    final user = ref.read(authProvider);
    if (user == null || user.idUser == null) return;

    // Tipe dompet dengan ikon dan warna
    final walletTypes = [
      _WalletType(
        value: 'Cash',
        label: 'Tunai',
        icon: Icons.payments_outlined,
        color: const Color(0xFF00897B),
      ),
      _WalletType(
        value: 'E-Wallet',
        label: 'E-Wallet',
        icon: Icons.phone_android_outlined,
        color: const Color(0xFF7B1FA2),
      ),
      _WalletType(
        value: 'Bank',
        label: 'Bank',
        icon: Icons.account_balance_outlined,
        color: _kPrimary,
      ),
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.all(20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add_card, color: _kPrimary, size: 22),
              ),
              const SizedBox(width: 10),
              const Text('Tambah Dompet Baru', style: TextStyle(fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nama Dompet',
                  hintText: 'e.g. OVO, BCA, Dompet Harian',
                  prefixIcon: const Icon(Icons.wallet_outlined, color: _kPrimary, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kPrimary, width: 2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: balanceController,
                decoration: InputDecoration(
                  labelText: 'Saldo Awal (Rp)',
                  prefixIcon: const Icon(Icons.attach_money, color: _kPrimary, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kPrimary, width: 2),
                  ),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              const Text(
                'Jenis Dompet',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Row(
                children: walletTypes.map((wt) {
                  final isSelected = jenisWallet == wt.value;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => jenisWallet = wt.value),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? wt.color : Colors.grey[50],
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? wt.color : Colors.grey[200]!,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: wt.color.withValues(alpha: 0.25),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  )
                                ]
                              : null,
                        ),
                        child: Column(
                          children: [
                            Icon(
                              wt.icon,
                              color: isSelected ? Colors.white : wt.color,
                              size: 24,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              wt.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? Colors.white : Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                final newWallet = WalletModel(
                  idUser: user.idUser!,
                  namaWallet: nameController.text,
                  saldo: double.tryParse(balanceController.text) ?? 0.0,
                  jenisWallet: jenisWallet,
                  catatanWallet: '',
                );
                final db = ref.read(databaseProvider);
                await db.insertWallet(newWallet);
                ref.read(walletProvider.notifier).refresh();
                await ref.read(authProvider.notifier).refreshUser();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Tambah Dompet'),
            ),
          ],
        ),
      ),
    );
  }

  // ── Bottom Sheet Daftar Dompet ────────────────────────────────────────
  void _showWalletListPopup(BuildContext context, List wallets) {
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
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
              'Daftar Dompet',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            ),
            const SizedBox(height: 8),
            if (wallets.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16.0),
                child: Text('Belum ada dompet'),
              )
            else
              ...wallets.map((wallet) => ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.account_balance_wallet, color: _kPrimary),
                    ),
                    title: Text(wallet.namaWallet),
                    subtitle: Text(fmt.format(wallet.saldo)),
                    onTap: () {
                      Navigator.pop(ctx);
                    },
                  )),
            const Divider(),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.add, color: Colors.green),
              ),
              title: const Text(
                'Tambah Dompet Baru',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showAddWalletDialog(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Voice Record ──────────────────────────────────────────────────────
  void _showVoiceRecordSheet(BuildContext context) {
    final user = ref.read(userProvider).value;
    final wallet = ref.read(walletProvider).value?.firstOrNull;

    if (user == null || wallet == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data user atau dompet tidak ditemukan.')),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => VoiceRecordSheet(
        userId: user.idUser!,
        walletId: wallet.idWallet!,
        onSuccess: () {
          // Refresh provider
          ref.invalidate(transactionProvider);
          ref.invalidate(walletProvider);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaksi berhasil ditambahkan!')),
          );
        },
      ),
    );
  }

  // ── Scan struk ────────────────────────────────────────────────────────
  void _showScanSourceOptions() {
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
                _processScan(ImageSource.camera);
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
                _processScan(ImageSource.gallery);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Future<void> _processScan(ImageSource source) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: _kPrimary),
                SizedBox(height: 16),
                Text('Sedang membaca struk...'),
              ],
            ),
          ),
        ),
      ),
    );

    final parsed = await ref
        .read(receiptParserProvider.notifier)
        .parseReceipt(source);
    if (mounted) Navigator.pop(context);

    final parserState = ref.read(receiptParserProvider);
    if (!mounted) return;

    if (parserState.errorMessage != null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Scan Gagal'),
          content: Text(parserState.errorMessage!),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _openAddSheet();
              },
              child: const Text('Catat Manual'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        ),
      );
    } else if (parsed != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => ScanConfirmationDialog(parsedReceipt: parsed),
      );
    }
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const AddTransactionSheet(),
    );
  }

  // ── Builder helpers ───────────────────────────────────────────────────
  /// Kartu Aksi Cepat (grid shortcut)
  Widget _buildQuickAction({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 10, color: Colors.grey[500]),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header dengan gradient biru + Balance Card ────────────────────────
  Widget _buildHeaderWithBalance(
    String userName, {
    double totalBalance = 0,
    double totalIn = 0,
    double totalOut = 0,
    NumberFormat? fmt,
    List wallets = const [],
    bool isLoading = false,
  }) {
    final formatter = fmt ?? NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kPrimary, _kPrimaryLight, _kPrimaryAccent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hai, $userName 👋',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Ayo kelola uang lebih baik!',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const NotificationScreen(),
                        ),
                      );
                    },
                    child: Container(
                      color: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(
                            Icons.notifications_none,
                            color: Colors.white,
                            size: 26,
                          ),
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              width: 9,
                              height: 9,
                              decoration: BoxDecoration(
                                color: Colors.orange[400],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),
              // ── Balance Card (menyatu di dalam header) ──
              if (isLoading)
                const SizedBox(
                  height: 140,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              else
                _buildBalanceCard(
                  totalBalance, totalIn, totalOut, formatter, wallets,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Kartu Saldo Utama (glassmorphism, di dalam header) ─────────────────
  Widget _buildBalanceCard(
    double total,
    double totalIn,
    double totalOut,
    NumberFormat fmt,
    List wallets,
  ) {
    // Nama wallet pertama sebagai label "bank"
    final bankName = wallets.isNotEmpty
        ? (wallets.first.namaWallet as String)
        : 'Dompet';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.25),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Total Saldo',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    fmt.format(total),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              // Dropdown bank
              GestureDetector(
                onTap: () => _showWalletListPopup(context, wallets),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.account_balance,
                        color: Colors.white,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        bankName,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.unfold_more,
                        color: Colors.white70,
                        size: 14,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Sub-kartu pemasukan & pengeluaran
          Row(
            children: [
              Expanded(
                child: _buildSubCard(
                  'Pemasukan',
                  totalIn,
                  fmt,
                  Icons.arrow_upward,
                  Colors.green[600]!,
                  Colors.green[700]!,
                  Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSubCard(
                  'Pengeluaran',
                  totalOut,
                  fmt,
                  Icons.arrow_downward,
                  Colors.red[600]!,
                  Colors.red[700]!,
                  Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubCard(
    String label,
    double amount,
    NumberFormat fmt,
    IconData icon,
    Color iconColor,
    Color amountColor,
    Color bgColor,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: iconColor, size: 14),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(color: Colors.black54, fontSize: 11, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            fmt.format(amount),
            style: TextStyle(
              color: amountColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Tab Periode & Kalender ──────────────────────────────────────────
  Widget _buildPeriodSection(List transactions, NumberFormat fmt) {
    final now = DateTime.now();
    DateTime startDate;
    DateTime endDate;

    final yesterday = DateTime(now.year, now.month, now.day).subtract(const Duration(days: 1));
    final endOfDayYesterday = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);

    switch (_selectedPeriodTab) {
      case 1: // Bulan Lalu
        startDate = DateTime(yesterday.year, yesterday.month - 1, yesterday.day);
        endDate = endOfDayYesterday;
        break;
      case 2: // 3 Bulan Lalu
        startDate = DateTime(yesterday.year, yesterday.month - 3, yesterday.day);
        endDate = endOfDayYesterday;
        break;
      case 0: // Minggu Lalu
      default:
        startDate = yesterday.subtract(const Duration(days: 6));
        endDate = endOfDayYesterday;
        break;
    }

    // Filter transactions to period
    final typedTxs = transactions.cast<TransactionModel>();
    final filteredTxs = typedTxs.where((tx) {
      final d = tx.timeStamp;
      return !d.isBefore(startDate) && !d.isAfter(endDate);
    }).toList();

    // Sort by timestamp descending
    filteredTxs.sort((a, b) => b.timeStamp.compareTo(a.timeStamp));

    double periodIn = 0;
    double periodOut = 0;
    for (final tx in filteredTxs) {
      if (tx.jenisArusKas == 'IN') periodIn += tx.nominal;
      if (tx.jenisArusKas == 'OUT') periodOut += tx.nominal;
    }
    double periodNet = periodIn - periodOut;

    final dateFormatter = DateFormat('dd MMM yyyy');
    final activeRangeText = '${dateFormatter.format(startDate)} - ${dateFormatter.format(endDate)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab scroll horizontal
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _periodTabs.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final isActive = _selectedPeriodTab == i;
              return GestureDetector(
                onTap: () {
                  if (i == 3) {
                    _selectCalendarDate(context, typedTxs, fmt);
                  } else {
                    setState(() {
                      _selectedPeriodTab = i;
                    });
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isActive ? _kPrimary : Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isActive ? _kPrimary : Colors.grey[300]!,
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: _kPrimary.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: Row(
                    children: [
                      if (i == 4) ...[
                        Icon(
                          Icons.calendar_month,
                          size: 14,
                          color: isActive ? Colors.white : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                      ],
                      Text(
                        _periodTabs[i],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isActive ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Active range display & Print PDF action button
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.date_range, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 6),
              Text(
                activeRangeText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Summary tiles
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryTile(
                  'Pemasukan',
                  fmt.format(periodIn),
                  Colors.green[600]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryTile(
                  'Pengeluaran',
                  fmt.format(periodOut),
                  Colors.red[400]!,
                ),
              ),
            ],
          ),
        ),
        // Net balance summary
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: periodNet >= 0 ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: periodNet >= 0 ? Colors.green[100]! : Colors.red[100]!,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selisih Bersih',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: periodNet >= 0 ? Colors.green[800] : Colors.red[800],
                  ),
                ),
                Text(
                  '${periodNet >= 0 ? "+" : ""}${fmt.format(periodNet)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: periodNet >= 0 ? Colors.green[700] : Colors.red[700],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryTile(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  // ── Line Chart ────────────────────────────────────────────────────────
  Widget _buildLineChart(List transactions, NumberFormat fmt) {
    final now = DateTime.now();
    final last7Days = List.generate(
      7,
      (i) => now.subtract(Duration(days: 6 - i)),
    );

    List<FlSpot> incomeSpots = [];
    List<FlSpot> expenseSpots = [];
    double maxY = 0;

    for (int i = 0; i < 7; i++) {
      final date = last7Days[i];
      double dailyIn = 0;
      double dailyOut = 0;
      for (var tx in transactions) {
        final d = tx.timeStamp as DateTime;
        if (d.year == date.year && d.month == date.month && d.day == date.day) {
          if (tx.jenisArusKas == 'IN') dailyIn += tx.nominal as double;
          if (tx.jenisArusKas == 'OUT') dailyOut += tx.nominal as double;
        }
      }
      incomeSpots.add(FlSpot(i.toDouble(), dailyIn));
      expenseSpots.add(FlSpot(i.toDouble(), dailyOut));
      if (dailyIn > maxY) maxY = dailyIn;
      if (dailyOut > maxY) maxY = dailyOut;
    }
    if (maxY == 0) maxY = 10000;

    // Warna premium
    const incomeColor = Color(0xFF00C853);
    const expenseColor = Color(0xFFFF5252);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row: Legend + period label
          Row(
            children: [
              _legendPill(incomeColor, 'Pemasukan'),
              const SizedBox(width: 12),
              _legendPill(expenseColor, 'Pengeluaran'),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '7 Hari',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _kPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  handleBuiltInTouches: true,
                  touchTooltipData: LineTouchTooltipData(
                    tooltipPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    getTooltipColor: (_) => const Color(0xFF1E293B),
                    getTooltipItems: (spots) => spots.map((s) {
                      final isIncome = s.barIndex == 0;
                      return LineTooltipItem(
                        fmt.format(s.y),
                        TextStyle(
                          color: isIncome ? const Color(0xFF69F0AE) : const Color(0xFFFF8A80),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      );
                    }).toList(),
                  ),
                  getTouchedSpotIndicator: (data, indices) =>
                      indices.map((i) => TouchedSpotIndicatorData(
                        FlLine(
                          color: Colors.grey.withValues(alpha: 0.3),
                          strokeWidth: 1,
                          dashArray: [4, 4],
                        ),
                        FlDotData(
                          show: true,
                          getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                            radius: 6,
                            color: Colors.white,
                            strokeWidth: 3,
                            strokeColor: data.color ?? _kPrimary,
                          ),
                        ),
                      )).toList(),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxY > 0 ? maxY * 1.25 / 4 : 2500,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: Colors.grey.withValues(alpha: 0.08),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 42,
                      interval: maxY > 0 ? maxY * 1.25 / 4 : 2500,
                      getTitlesWidget: (val, _) {
                        if (val == 0) return const SizedBox();
                        String label;
                        if (val >= 1000000) {
                          label = '${(val / 1000000).toStringAsFixed(1)}jt';
                        } else if (val >= 1000) {
                          label = '${(val / 1000).toStringAsFixed(0)}rb';
                        } else {
                          label = val.toStringAsFixed(0);
                        }
                        return Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[400],
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 30,
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= 7) return const SizedBox();
                        final day = last7Days[idx];
                        final isToday = day.day == now.day && day.month == now.month && day.year == now.year;
                        return Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                DateFormat('dd').format(day),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                  color: isToday ? _kPrimary : Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxY * 1.25,
                lineBarsData: [
                  // Garis Pemasukan — Premium Style
                  LineChartBarData(
                    spots: incomeSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    preventCurveOverShooting: true,
                    color: incomeColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    shadow: Shadow(
                      color: incomeColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2.5,
                        strokeColor: incomeColor,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          incomeColor.withValues(alpha: 0.25),
                          incomeColor.withValues(alpha: 0.08),
                          incomeColor.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                  // Garis Pengeluaran — Premium Style
                  LineChartBarData(
                    spots: expenseSpots,
                    isCurved: true,
                    curveSmoothness: 0.35,
                    preventCurveOverShooting: true,
                    color: expenseColor,
                    barWidth: 3,
                    isStrokeCapRound: true,
                    shadow: Shadow(
                      color: expenseColor.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                    dotData: FlDotData(
                      show: true,
                      getDotPainter: (spot, percent, barData, index) => FlDotCirclePainter(
                        radius: 4,
                        color: Colors.white,
                        strokeWidth: 2.5,
                        strokeColor: expenseColor,
                      ),
                    ),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          expenseColor.withValues(alpha: 0.18),
                          expenseColor.withValues(alpha: 0.05),
                          expenseColor.withValues(alpha: 0.0),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendPill(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final walletState = ref.watch(walletProvider);
    final transactionState = ref.watch(transactionProvider);
    final categoriesState = ref.watch(categoryProvider);
    final categories = categoriesState.value ?? [];
    final fmt = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FB),
      body: RefreshIndicator(
        color: _kPrimary,
        onRefresh: () async {
          ref.read(walletProvider.notifier).refresh();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header biru + Balance Card (menyatu) ──
            SliverToBoxAdapter(
              child: userState.when(
                data: (user) {
                  final userName = user?.nama ?? 'User';
                  return walletState.when(
                    data: (wallets) {
                      final totalBalance = ref
                          .read(walletProvider.notifier)
                          .getTotalBalance(wallets);
                      return transactionState.when(
                        data: (txs) {
                          double totalIn = 0, totalOut = 0;
                          for (final tx in txs) {
                            if (tx.jenisArusKas == 'IN') {
                              totalIn += tx.nominal;
                            }
                            if (tx.jenisArusKas == 'OUT') {
                              totalOut += tx.nominal;
                            }
                          }
                          return _buildHeaderWithBalance(
                            userName,
                            totalBalance: totalBalance,
                            totalIn: totalIn,
                            totalOut: totalOut,
                            fmt: fmt,
                            wallets: wallets,
                          );
                        },
                        loading: () => _buildHeaderWithBalance(
                          userName,
                          totalBalance: totalBalance,
                          fmt: fmt,
                          wallets: wallets,
                        ),
                        error: (e, s) => _buildHeaderWithBalance(
                          userName,
                          totalBalance: totalBalance,
                          fmt: fmt,
                          wallets: wallets,
                        ),
                      );
                    },
                    loading: () => _buildHeaderWithBalance(
                      userName,
                      isLoading: true,
                      fmt: fmt,
                    ),
                    error: (e, s) => _buildHeaderWithBalance(userName, fmt: fmt),
                  );
                },
                loading: () => _buildHeaderWithBalance('...', isLoading: true, fmt: fmt),
                error: (e, s) => _buildHeaderWithBalance('User', fmt: fmt),
              ),
            ),

            // ── AI Welcome Message ──
            SliverToBoxAdapter(
              child: Consumer(
                builder: (context, ref, _) {
                  // SEMENTARA JANGAN DITAMPILKAN
                  return const SizedBox.shrink();

                  /*
                  final welcomeMsg = ref.watch(welcomeAiProvider);
                  return welcomeMsg.when(
                    data: (msg) {
                      if (msg == null || msg.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: Colors.blue[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blue[100]!),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.auto_awesome,
                                color: _kPrimary,
                                size: 18,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  msg,
                                  style: TextStyle(
                                    color: Colors.blue[900],
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                    loading: () => const Padding(
                      padding: EdgeInsets.fromLTRB(20, 16, 20, 0),
                      child: LinearProgressIndicator(color: _kPrimary),
                    ),
                    error: (error, stackTrace) => const SizedBox.shrink(),
                  );
                  */
                },
              ),
            ),

            // ── Tab Minggu + Ringkasan ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: transactionState.when(
                  data: (txs) => _buildPeriodSection(txs, fmt),
                  loading: () => const SizedBox(),
                  error: (error, stackTrace) => const SizedBox(),
                ),
              ),
            ),

            // ── Aksi Cepat ──
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  'Aksi Cepat',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 2.8,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                delegate: SliverChildListDelegate([
                  _buildQuickAction(
                    title: 'Catat Suara',
                    subtitle: 'Pakai AI',
                    icon: Icons.mic_none,
                    iconColor: Colors.pink,
                    bgColor: Colors.pink[50]!,
                    onTap: () => _showVoiceRecordSheet(context),
                  ),
                  _buildQuickAction(
                    title: 'Scan Struk',
                    subtitle: 'Catat otomatis',
                    icon: Icons.document_scanner_outlined,
                    iconColor: Colors.purple,
                    bgColor: Colors.purple[50]!,
                    onTap: _showScanSourceOptions,
                  ),
                  _buildQuickAction(
                    title: 'Laporan PDF',
                    subtitle: 'Unduh laporan',
                    icon: Icons.picture_as_pdf_outlined,
                    iconColor: Colors.orange[700]!,
                    bgColor: Colors.orange[50]!,
                    onTap: () {
                      final txs = transactionState.value ?? [];
                      if (txs.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Tidak ada transaksi untuk dicetak')),
                        );
                        return;
                      }
                      final user = userState.value;
                      ReportPdfService.generateAndPrint(
                        txs,
                        user?.nama ?? 'User',
                        'Laporan Transaksi',
                      );
                    },
                  ),
                  _buildQuickAction(
                    title: 'Tanya AI',
                    subtitle: 'Konsultasi uang',
                    icon: Icons.auto_awesome_outlined,
                    iconColor: Colors.teal,
                    bgColor: Colors.teal[50]!,
                    onTap: () =>
                        ref.read(activePageProvider.notifier).setPage(2),
                  ),
                  _buildQuickAction(
                    title: 'Tambah Dompet',
                    subtitle: 'Tambah akun baru',
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: _kPrimary,
                    bgColor: Colors.blue[50]!,
                    onTap: () => _showAddWalletDialog(context),
                  ),
                  _buildQuickAction(
                    title: 'Kalender',
                    subtitle: 'Detail harian',
                    icon: Icons.calendar_month_outlined,
                    iconColor: Colors.indigo[700]!,
                    bgColor: Colors.indigo[50]!,
                    onTap: () {
                      final txs = transactionState.value ?? [];
                      _selectCalendarDate(context, txs, fmt);
                    },
                  ),
                ]),
              ),
            ),

            // ── Grafik Arus Kas ──
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Text(
                  'Aktivitas 7 Hari Terakhir',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: transactionState.when(
                data: (txs) => _buildLineChart(txs, fmt),
                loading: () => const SizedBox(
                  height: 200,
                  child: Center(
                    child: CircularProgressIndicator(color: _kPrimary),
                  ),
                ),
                error: (error, stackTrace) => const SizedBox(
                  height: 200,
                  child: Center(child: Text('Gagal memuat grafik')),
                ),
              ),
            ),

            // ── Transaksi Terakhir ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Transaksi Terakhir',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        ref.read(activePageProvider.notifier).setPage(1);
                      },
                      child: const Text(
                        'Lihat Semua',
                        style: TextStyle(color: _kPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            transactionState.when(
              data: (txs) {
                if (txs.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'Belum ada transaksi',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    ),
                  );
                }
                final shown = txs.take(5).toList();
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, i) {
                      final tx = shown[i];
                      final isOut = tx.jenisArusKas == 'OUT';
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: isOut
                                    ? Colors.red[50]
                                    : Colors.green[50],
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isOut
                                    ? Icons.arrow_downward
                                    : Icons.arrow_upward,
                                color: isOut
                                    ? Colors.red[400]
                                    : Colors.green[600],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.judulTransaksi,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isOut ? Colors.red[50] : Colors.green[50],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          (() {
                                            final cat = categories.firstWhere(
                                              (c) => c.idKategori == tx.idKategori,
                                              orElse: () => CategoryModel(
                                                namaKategori: 'Lainnya',
                                                jenisArusKas: '',
                                              ),
                                            );
                                            return cat.namaKategori;
                                          })(),
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: isOut ? Colors.red[600] : Colors.green[700],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        DateFormat(
                                          'dd MMM yyyy',
                                        ).format(tx.timeStamp),
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey[500],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${isOut ? "-" : "+"}${fmt.format(tx.nominal)}',
                              style: TextStyle(
                                color: isOut
                                    ? Colors.red[400]
                                    : Colors.green[600],
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      );
                    }, childCount: shown.length),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(
                  child: CircularProgressIndicator(color: _kPrimary),
                ),
              ),
              error: (error, stackTrace) => const SliverToBoxAdapter(
                child: Center(child: Text('Gagal memuat transaksi')),
              ),
            ),

            // Padding bawah agar tidak tertutup bottom nav
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }
}
