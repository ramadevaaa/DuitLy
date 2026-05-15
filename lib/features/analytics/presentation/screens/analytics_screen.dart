import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:duitly/features/transaction/presentation/providers/analytics_provider.dart';
import 'package:duitly/features/transaction/presentation/providers/category_provider.dart';
import 'package:duitly/features/transaction/data/models/category_model.dart';
import 'package:duitly/features/auth/presentation/providers/auth_provider.dart';
import 'package:duitly/features/transaction/presentation/providers/report_pdf_service.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(filterProvider);
    final filteredTx = ref.watch(filteredTransactionProvider);
    final spendingMap = ref.watch(spendingByCategoryProvider);
    final categoriesAsync = ref.watch(categoryProvider);
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    final colors = [
      Colors.blue, Colors.red, Colors.green, Colors.orange,
      Colors.purple, Colors.teal, Colors.amber, Colors.cyan,
    ];

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Analisis Keuangan', style: TextStyle(color: Colors.black)),
        actions: [
          Consumer(builder: (context, ref, _) {
            return IconButton(
              icon: const Icon(Icons.print, color: Colors.blue),
              tooltip: 'Cetak Laporan PDF',
              onPressed: () {
                final filteredTx = ref.read(filteredTransactionProvider);
                final user = ref.read(authProvider);
                final filter = ref.read(filterProvider);
                
                filteredTx.whenData((transactions) {
                  if (transactions.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada transaksi untuk dicetak.')));
                    return;
                  }
                  
                  String periodLabel = '';
                  switch (filter) {
                    case TransactionFilter.week7: periodLabel = '7 Hari Terakhir'; break;
                    case TransactionFilter.month1: periodLabel = '30 Hari Terakhir'; break;
                    case TransactionFilter.month3: periodLabel = '3 Bulan Terakhir'; break;
                    case TransactionFilter.year1: periodLabel = '1 Tahun Terakhir'; break;
                  }

                  ReportPdfService.generateAndPrint(transactions, user?.nama ?? 'User', periodLabel);
                });
              },
            );
          }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter Chips
            const Text('Rentang Waktu', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(label: '7 Hari', value: TransactionFilter.week7, current: filter, ref: ref),
                  const SizedBox(width: 8),
                  _FilterChip(label: '30 Hari', value: TransactionFilter.month1, current: filter, ref: ref),
                  const SizedBox(width: 8),
                  _FilterChip(label: '3 Bulan', value: TransactionFilter.month3, current: filter, ref: ref),
                  const SizedBox(width: 8),
                  _FilterChip(label: '1 Tahun', value: TransactionFilter.year1, current: filter, ref: ref),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Pie Chart
            const Text('Pengeluaran per Kategori', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            spendingMap.when(
              data: (map) {
                if (map.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32.0),
                      child: Text('Belum ada data pengeluaran', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }

                final entries = map.entries.toList();
                final total = map.values.fold(0.0, (a, b) => a + b);

                return categoriesAsync.when(
                  data: (categories) {
                    CategoryModel? getCat(int id) {
                      try {
                        return categories.firstWhere((c) => c.idKategori == id);
                      } catch (_) {
                        return null;
                      }
                    }

                    return Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10)],
                      ),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 220,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 50,
                                sections: entries.asMap().entries.map((e) {
                                  final idx = e.key;
                                  final entry = e.value;
                                  final pct = (entry.value / total) * 100;
                                  return PieChartSectionData(
                                    color: colors[idx % colors.length],
                                    value: entry.value,
                                    title: '${pct.toStringAsFixed(0)}%',
                                    radius: 60,
                                    titleStyle: const TextStyle(
                                      fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Legend
                          ...entries.asMap().entries.map((e) {
                            final idx = e.key;
                            final entry = e.value;
                            final cat = getCat(entry.key);
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Container(width: 14, height: 14, decoration: BoxDecoration(
                                    color: colors[idx % colors.length],
                                    shape: BoxShape.circle,
                                  )),
                                  const SizedBox(width: 8),
                                  Expanded(child: Text(cat?.namaKategori ?? 'Kategori #${entry.key}')),
                                  Text(currencyFormat.format(entry.value), style: const TextStyle(fontWeight: FontWeight.bold)),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const Text('Gagal memuat kategori'),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Gagal memuat data'),
            ),

            const SizedBox(height: 24),

            // Transaction History
            const Text('Riwayat Transaksi', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            filteredTx.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text('Tidak ada transaksi di periode ini', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }
                return Column(
                  children: transactions.map((tx) {
                    final isOut = tx.jenisArusKas == 'OUT';
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6)],
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: isOut ? Colors.red[50] : Colors.green[50],
                          child: Icon(
                            isOut ? Icons.arrow_downward : Icons.arrow_upward,
                            color: isOut ? Colors.red : Colors.green,
                          ),
                        ),
                        title: Text(tx.judulTransaksi, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          DateFormat('dd MMM yyyy, HH:mm').format(tx.timeStamp),
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        trailing: Text(
                          '${isOut ? "-" : "+"}${currencyFormat.format(tx.nominal)}',
                          style: TextStyle(
                            color: isOut ? Colors.red : Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Gagal memuat transaksi'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final TransactionFilter value;
  final TransactionFilter current;
  final WidgetRef ref;

  const _FilterChip({required this.label, required this.value, required this.current, required this.ref});

  @override
  Widget build(BuildContext context) {
    final isSelected = value == current;
    return GestureDetector(
      onTap: () => ref.read(filterProvider.notifier).setFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.blue : Colors.grey[300]!),
        ),
        child: Text(
          label,
          style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}
