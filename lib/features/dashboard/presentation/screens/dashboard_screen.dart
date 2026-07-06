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
import 'package:duitly/features/dashboard/presentation/providers/welcome_ai_provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:duitly/core/navigation/main_shell.dart';
import 'package:duitly/features/transaction/presentation/providers/receipt_parser_provider.dart';
import 'package:duitly/features/transaction/presentation/widgets/scan_confirmation_dialog.dart';
import 'package:duitly/features/transaction/presentation/widgets/add_transaction_sheet.dart';
import 'package:duitly/features/dashboard/presentation/screens/notification_screen.dart';


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
  int _selectedWeekTab = 0;
  final _searchController = TextEditingController();

  // --- Daftar tab minggu (7 hari terakhir per minggu) ---
  List<String> get _weekTabs {
    final now = DateTime.now();
    final formatter = DateFormat('dd/MM/yyyy');
    return [
      'Minggu Ini',
      formatter.format(now.subtract(const Duration(days: 7))),
      formatter.format(now.subtract(const Duration(days: 14))),
      formatter.format(now.subtract(const Duration(days: 21))),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
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
              const SizedBox(height: 16),
              // Search bar
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.search, color: Colors.white70, size: 18),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Cari fitur...',
                          hintStyle: TextStyle(
                            color: Colors.white60,
                            fontSize: 14,
                          ),
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
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
              Container(
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
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSubCard(
                  'Pengeluaran',
                  totalOut,
                  fmt,
                  Icons.arrow_downward,
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
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.white70, size: 13),
              const SizedBox(width: 4),
              Text(
                label,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            fmt.format(amount),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // ── Tab Minggu ────────────────────────────────────────────────────────
  Widget _buildWeeklySection(List transactions, NumberFormat fmt) {
    // Hitung saldo awal dan akhir berdasarkan tab yang dipilih
    final now = DateTime.now();
    final offsetDays = _selectedWeekTab * 7;
    final endDate = now.subtract(Duration(days: offsetDays));
    final startDate = endDate.subtract(const Duration(days: 6));

    double weekIn = 0;
    double weekOut = 0;
    for (final tx in transactions) {
      final d = tx.timeStamp as DateTime;
      if (!d.isBefore(
            DateTime(startDate.year, startDate.month, startDate.day),
          ) &&
          !d.isAfter(
            DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59),
          )) {
        if (tx.jenisArusKas == 'IN') weekIn += tx.nominal as double;
        if (tx.jenisArusKas == 'OUT') weekOut += tx.nominal as double;
      }
    }
    final weekNet = weekIn - weekOut;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Tab scroll horizontal
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _weekTabs.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final isActive = _selectedWeekTab == i;
              return GestureDetector(
                onTap: () => setState(() => _selectedWeekTab = i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
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
                  child: Text(
                    _weekTabs[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isActive ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _buildSummaryTile(
                  'Saldo Awal',
                  fmt.format(weekOut),
                  Colors.red[400]!,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryTile(
                  'Saldo Akhir',
                  fmt.format(weekNet < 0 ? 0 : weekNet),
                  Colors.green[600]!,
                ),
              ),
            ],
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

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Legend
          Row(
            children: [
              _legendDot(Colors.green, 'Pemasukan'),
              const SizedBox(width: 16),
              _legendDot(Colors.red, 'Pengeluaran'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                lineTouchData: LineTouchData(
                  touchTooltipData: LineTouchTooltipData(
                    getTooltipColor: (_) => Colors.blueGrey.shade800,
                    getTooltipItems: (spots) => spots
                        .map(
                          (s) => LineTooltipItem(
                            fmt.format(s.y),
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (_) =>
                      FlLine(color: Colors.grey[100]!, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      reservedSize: 24,
                      getTitlesWidget: (val, _) {
                        final idx = val.toInt();
                        if (idx < 0 || idx >= 7) return const SizedBox();
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            DateFormat('dd/MM').format(last7Days[idx]),
                            style: TextStyle(
                              fontSize: 9,
                              color: Colors.grey[400],
                            ),
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
                  // Garis Pemasukan
                  LineChartBarData(
                    spots: incomeSpots,
                    isCurved: true,
                    curveSmoothness: 0.4,
                    color: Colors.green[600],
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withValues(alpha: 0.15),
                          Colors.green.withValues(alpha: 0.01),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                  // Garis Pengeluaran
                  LineChartBarData(
                    spots: expenseSpots,
                    isCurved: true,
                    curveSmoothness: 0.4,
                    color: Colors.red[400],
                    barWidth: 2.5,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Colors.red.withValues(alpha: 0.12),
                          Colors.red.withValues(alpha: 0.01),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
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

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final userState = ref.watch(userProvider);
    final walletState = ref.watch(walletProvider);
    final transactionState = ref.watch(transactionProvider);
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
                },
              ),
            ),

            // ── Tab Minggu + Ringkasan ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 20),
                child: transactionState.when(
                  data: (txs) => _buildWeeklySection(txs, fmt),
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
                    onTap: () =>
                        ref.read(activePageProvider.notifier).setPage(2),
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
                ]),
              ),
            ),

            // ── Daftar Dompet ──
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Dompet Anda',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _showAddWalletDialog(context),
                      icon: const Icon(Icons.add, size: 18, color: _kPrimary),
                      label: const Text(
                        'Tambah',
                        style: TextStyle(color: _kPrimary),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: SizedBox(
                height: 110,
                child: walletState.when(
                  data: (wallets) => ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: wallets.length + 1,
                    itemBuilder: (context, index) {
                      if (index == wallets.length) {
                        return GestureDetector(
                          onTap: () => _showAddWalletDialog(context),
                          child: Container(
                            width: 110,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_circle_outline,
                                  color: _kPrimary,
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  'Tambah\nDompet',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: _kPrimary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }
                      final wallet = wallets[index];
                      return Container(
                        width: 160,
                        margin: const EdgeInsets.only(right: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              wallet.namaWallet,
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              fmt.format(wallet.saldo),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: _kPrimary),
                  ),
                  error: (error, stackTrace) =>
                      const Center(child: Text('Gagal memuat dompet')),
                ),
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
                      onPressed: () {},
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
                                  const SizedBox(height: 2),
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
