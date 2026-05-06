import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:duitly/features/user/presentation/providers/user_provider.dart';
import 'package:duitly/features/auth/presentation/providers/auth_provider.dart';
import 'package:duitly/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:duitly/features/wallet/data/models/wallet_model.dart';
import 'package:duitly/features/transaction/presentation/providers/transaction_provider.dart';
import 'package:duitly/features/transaction/presentation/widgets/add_transaction_sheet.dart';
import 'package:duitly/core/providers/database_provider.dart';

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
                  value: jenisWallet,
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
          error: (_, __) => const Text('DuitLy', style: TextStyle(color: Colors.black)),
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
                      error: (_, __) => const Text('Error', style: TextStyle(color: Colors.white, fontSize: 32)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Wallet Carousel Header
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
                  error: (_, __) => const Text('Gagal memuat dompet'),
                ),
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
                error: (_, __) => const Text('Gagal memuat transaksi'),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
            builder: (context) => const AddTransactionSheet(),
          );
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
