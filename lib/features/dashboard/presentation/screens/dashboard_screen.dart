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

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  // Dialog Tambah Wallet
  void _showAddWalletDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    String jenisWallet = 'Cash'; // Default value
    final user = ref.read(authProvider);

    if (user == null || user.idUser == null) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Tambah Dompet Baru'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nama Dompet (e.g. OVO, Mandiri)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: balanceController,
                  decoration: const InputDecoration(labelText: 'Saldo Awal (Rp)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: jenisWallet,
                  decoration: const InputDecoration(labelText: 'Jenis Dompet', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'Cash', child: Text('Cash')),
                    DropdownMenuItem(value: 'E-Wallet', child: Text('E-Wallet')),
                    DropdownMenuItem(value: 'Bank', child: Text('Bank')),
                  ],
                  onChanged: (val) => setState(() => jenisWallet = val!),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
              ElevatedButton(
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
                child: const Text('Tambah'),
              ),
            ],
          );
        }
      ),
    );
  }

  void _showScanSourceOptions(BuildContext context, WidgetRef ref) {
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
                _processScan(context, ref, ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.blue),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(ctx);
                _processScan(context, ref, ImageSource.gallery);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _processScan(BuildContext context, WidgetRef ref, ImageSource source) async {
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

    final parsed = await ref.read(receiptParserProvider.notifier).parseReceipt(source);
    
    if (context.mounted) {
      Navigator.pop(context); // Close loading dialog
    }

    final parserState = ref.read(receiptParserProvider);
    if (parserState.errorMessage != null) {
      if (context.mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Scan Gagal'),
            content: Text(parserState.errorMessage!),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _openManualTransactionSheet(context);
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
      }
    } else if (parsed != null) {
      if (context.mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ScanConfirmationDialog(parsedReceipt: parsed),
        );
      }
    }
  }

  void _openManualTransactionSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => const AddTransactionSheet(),
    );
  }

  Widget _buildShortcutCard(
    BuildContext context, {
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey[200]!),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
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
              child: Icon(icon, color: iconColor, size: 22),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 10, color: Colors.grey[600]),
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);
    final walletState = ref.watch(walletProvider);
    final transactionState = ref.watch(transactionProvider);

    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: userState.when(
          data: (user) => Text('Hai, ${user?.nama ?? "User"}!', style: const TextStyle(color: Colors.black)),
          loading: () => const Text('Loading...', style: TextStyle(color: Colors.black)),
          error: (_, _) => const Text('DuitLy', style: TextStyle(color: Colors.black)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.black),
            onPressed: () {},
          ),
          const CircleAvatar(
            backgroundColor: Colors.blue,
            radius: 16,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.read(walletProvider.notifier).refresh();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Total Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.blue, Colors.blueAccent]),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Total Kekayaan', style: TextStyle(color: Colors.white70, fontSize: 16)),
                    const SizedBox(height: 8),
                    walletState.when(
                      data: (wallets) {
                        final total = ref.read(walletProvider.notifier).getTotalBalance(wallets);
                        return Text(
                          currencyFormat.format(total),
                          style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                        );
                      },
                      loading: () => const Text('...', style: TextStyle(color: Colors.white, fontSize: 32)),
                      error: (_, _) => const Text('Error', style: TextStyle(color: Colors.white, fontSize: 32)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              // AI Welcome Message
              Consumer(builder: (context, ref, _) {
                final welcomeMsg = ref.watch(welcomeAiProvider);
                return welcomeMsg.when(
                  data: (msg) {
                    if (msg == null || msg.isEmpty) return const SizedBox.shrink();
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.auto_awesome, color: Colors.blue, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              msg,
                              style: TextStyle(color: Colors.blue[800], fontSize: 13, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: LinearProgressIndicator()),
                  error: (_, _) => Container(
                    padding: const EdgeInsets.all(12),
                    child: const Text('Gagal memuat AI', style: TextStyle(color: Colors.red, fontSize: 10)),
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Aksi Cepat Grid
              const Text('Aksi Cepat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                childAspectRatio: 2.5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                children: [
                  _buildShortcutCard(
                    context,
                    title: 'Scan Struk',
                    subtitle: 'Catat otomatis',
                    icon: Icons.document_scanner_outlined,
                    iconColor: Colors.purple,
                    bgColor: Colors.purple[50]!,
                    onTap: () => _showScanSourceOptions(context, ref),
                  ),
                  _buildShortcutCard(
                    context,
                    title: 'Laporan PDF',
                    subtitle: 'Unduh laporan',
                    icon: Icons.picture_as_pdf_outlined,
                    iconColor: Colors.orange,
                    bgColor: Colors.orange[50]!,
                    onTap: () => ref.read(activePageProvider.notifier).setPage(1),
                  ),
                  _buildShortcutCard(
                    context,
                    title: 'Tanya AI',
                    subtitle: 'Konsultasi uang',
                    icon: Icons.auto_awesome_outlined,
                    iconColor: Colors.teal,
                    bgColor: Colors.teal[50]!,
                    onTap: () => ref.read(activePageProvider.notifier).setPage(2),
                  ),
                  _buildShortcutCard(
                    context,
                    title: 'Tambah Dompet',
                    subtitle: 'Tambah akun baru',
                    icon: Icons.account_balance_wallet_outlined,
                    iconColor: Colors.blue,
                    bgColor: Colors.blue[50]!,
                    onTap: () => _showAddWalletDialog(context, ref),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Dompet Anda', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton.icon(
                    onPressed: () => _showAddWalletDialog(context, ref),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Tambah'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 120,
                child: walletState.when(
                  data: (wallets) => ListView.builder(
                    scrollDirection: Axis.horizontal,
                    // +1 for the "Add Wallet" card at the end
                    itemCount: wallets.length + 1,
                    itemBuilder: (context, index) {
                      // Last card = Tambah Wallet button
                      if (index == wallets.length) {
                        return GestureDetector(
                          onTap: () => _showAddWalletDialog(context, ref),
                          child: Container(
                            width: 120,
                            margin: const EdgeInsets.only(right: 16),
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue, style: BorderStyle.solid),
                            ),
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline, color: Colors.blue, size: 32),
                                SizedBox(height: 8),
                                Text('Tambah\nDompet', textAlign: TextAlign.center, style: TextStyle(color: Colors.blue, fontSize: 12)),
                              ],
                            ),
                          ),
                        );
                      }
                      final wallet = wallets[index];
                      return Container(
                        width: 200,
                        margin: const EdgeInsets.only(right: 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(wallet.namaWallet, style: const TextStyle(color: Colors.grey)),
                            const SizedBox(height: 8),
                            Text(currencyFormat.format(wallet.saldo),
                                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      );
                    },
                  ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const Text('Gagal memuat dompet'),
                ),
              ),

              const SizedBox(height: 24),

              // Line Chart (Arus Kas 7 Hari Terakhir)
              const Text('Arus Kas 7 Hari Terakhir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              // Legend
              Row(
                children: [
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Pemasukan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(width: 16),
                  Container(width: 12, height: 12, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle)),
                  const SizedBox(width: 4),
                  const Text('Pengeluaran', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 16),
              transactionState.when(
                data: (transactions) {
                  final now = DateTime.now();
                  final last7Days = List.generate(7, (index) => now.subtract(Duration(days: 6 - index)));
                  
                  List<FlSpot> incomeSpots = [];
                  List<FlSpot> expenseSpots = [];
                  double maxY = 0;

                  for (int i = 0; i < 7; i++) {
                    final date = last7Days[i];
                    double dailyIn = 0;
                    double dailyOut = 0;

                    for (var tx in transactions) {
                      if (tx.timeStamp.year == date.year &&
                          tx.timeStamp.month == date.month &&
                          tx.timeStamp.day == date.day) {
                        if (tx.jenisArusKas == 'IN') dailyIn += tx.nominal;
                        if (tx.jenisArusKas == 'OUT') dailyOut += tx.nominal;
                      }
                    }

                    incomeSpots.add(FlSpot(i.toDouble(), dailyIn));
                    expenseSpots.add(FlSpot(i.toDouble(), dailyOut));
                    
                    if (dailyIn > maxY) maxY = dailyIn;
                    if (dailyOut > maxY) maxY = dailyOut;
                  }

                  if (maxY == 0) maxY = 10000;

                  return Container(
                    height: 200,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                    ),
                    child: LineChart(
                      LineChartData(
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipColor: (touchedSpot) => Colors.blueGrey.shade800,
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                return LineTooltipItem(
                                  currencyFormat.format(spot.y),
                                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                );
                              }).toList();
                            },
                          ),
                        ),
                        gridData: const FlGridData(show: false),
                        titlesData: FlTitlesData(
                          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                if (value.toInt() >= 0 && value.toInt() < 7) {
                                  final date = last7Days[value.toInt()];
                                  return Padding(
                                    padding: const EdgeInsets.only(top: 8.0),
                                    child: Text(DateFormat('dd/MM').format(date), style: const TextStyle(fontSize: 10, color: Colors.grey)),
                                  );
                                }
                                return const Text('');
                              },
                              interval: 1,
                              reservedSize: 22,
                            ),
                          ),
                        ),
                        borderData: FlBorderData(show: false),
                        minX: 0,
                        maxX: 6,
                        minY: 0,
                        maxY: maxY * 1.2,
                        lineBarsData: [
                          LineChartBarData(
                            spots: incomeSpots,
                            isCurved: true,
                            color: Colors.green,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: true, color: Colors.green.withValues(alpha: 0.1)),
                          ),
                          LineChartBarData(
                            spots: expenseSpots,
                            isCurved: true,
                            color: Colors.red,
                            barWidth: 3,
                            isStrokeCapRound: true,
                            dotData: const FlDotData(show: false),
                            belowBarData: BarAreaData(show: true, color: Colors.red.withValues(alpha: 0.1)),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                loading: () => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                error: (_, _) => const SizedBox(height: 200, child: Center(child: Text('Gagal memuat grafik'))),
              ),
              const SizedBox(height: 24),

              // Recent Activity
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Transaksi Terakhir', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () {}, child: const Text('Lihat Semua')),
                ],
              ),
              transactionState.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(20.0),
                        child: Text('Belum ada transaksi'),
                      ),
                    );
                  }
                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: transactions.length > 5 ? 5 : transactions.length,
                    itemBuilder: (context, index) {
                      final tx = transactions[index];
                      final isOut = tx.jenisArusKas == 'OUT';
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: isOut ? Colors.red[50] : Colors.green[50],
                          child: Icon(
                            isOut ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isOut ? Colors.red : Colors.green,
                          ),
                        ),
                        title: Text(tx.judulTransaksi, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(DateFormat('dd MMM yyyy').format(tx.timeStamp)),
                        trailing: Text(
                          '${isOut ? "-" : "+"}${currencyFormat.format(tx.nominal)}',
                          style: TextStyle(
                            color: isOut ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) => const Text('Gagal memuat transaksi'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
