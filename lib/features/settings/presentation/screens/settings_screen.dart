import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duitly/features/auth/presentation/providers/auth_provider.dart';
import 'package:duitly/features/user/presentation/providers/user_provider.dart';
import 'package:duitly/features/user/data/models/user_model.dart';
import 'package:duitly/features/wallet/presentation/providers/wallet_provider.dart';
import 'package:duitly/features/transaction/presentation/providers/category_provider.dart';
import 'package:duitly/features/transaction/data/models/category_model.dart';
import 'package:duitly/core/providers/database_provider.dart';
import 'package:duitly/core/navigation/main_shell.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userState = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: userState.when(
        data: (user) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Section: Profile
            _buildSectionHeader('Profil & Finansial'),
            _buildSettingItem(
              icon: Icons.person_outline,
              title: 'Edit Profil',
              subtitle: user?.nama ?? '-',
              onTap: () => _showEditProfileDialog(context, ref, user!),
            ),
            _buildSettingItem(
              icon: Icons.track_changes,
              title: 'Tujuan Finansial',
              subtitle: user?.tujuanFinansial ?? '-',
              onTap: () => _showEditProfileDialog(context, ref, user!),
            ),
            const SizedBox(height: 24),

            // Section: Wallets (Edit/Delete only - Add is from Dashboard)
            _buildSectionHeader('Manajemen Dompet'),
            _buildSettingItem(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Edit / Hapus Dompet',
              subtitle: 'Kelola sumber dana yang ada',
              onTap: () => _showWalletManager(context, ref),
            ),
            const SizedBox(height: 24),

            // Section: Categories
            _buildSectionHeader('Manajemen Kategori'),
            _buildSettingItem(
              icon: Icons.category_outlined,
              title: 'Kelola Kategori Transaksi',
              subtitle: 'Tambah atau hapus kategori',
              onTap: () => _showCategoryManager(context, ref),
            ),
            const SizedBox(height: 24),

            // Section: About
            _buildSectionHeader('Lainnya'),
            _buildSettingItem(
              icon: Icons.security,
              title: 'Privasi & Keamanan',
              subtitle: 'Data Anda tersimpan secara lokal',
              onTap: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'DuitLy',
                  applicationVersion: '1.0.0',
                  children: [
                    const Text(
                      'DuitLy menggunakan SQLite untuk menyimpan seluruh data Anda secara lokal di perangkat. '
                      'Tidak ada data yang dikirim ke server luar kecuali jika Anda menggunakan fitur AI (Gemini).',
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 12),
            _buildSettingItem(
              icon: Icons.logout,
              title: 'Keluar',
              subtitle: 'Akhiri sesi Anda',
              onTap: () {
                _showLogoutDialog(context, ref);
              },
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }

  Widget _buildSettingItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 20),
        onTap: onTap,
      ),
    );
  }

  // DIALOG: Edit Profil
  void _showEditProfileDialog(BuildContext context, WidgetRef ref, UserModel user) {
    final nameController = TextEditingController(text: user.nama);
    final goalController = TextEditingController(text: user.tujuanFinansial);
    final incomeController = TextEditingController(text: user.kisaranPendapatan.toString());

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Profil'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Nama', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(controller: goalController, decoration: const InputDecoration(labelText: 'Tujuan Finansial', border: OutlineInputBorder())),
            const SizedBox(height: 12),
            TextField(
              controller: incomeController,
              decoration: const InputDecoration(labelText: 'Pendapatan Bulanan (Rp)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final updatedUser = UserModel(
                idUser: user.idUser,
                nama: nameController.text,
                email: user.email,
                password: user.password,
                tujuanFinansial: goalController.text,
                kisaranPendapatan: double.tryParse(incomeController.text) ?? user.kisaranPendapatan,
                totalKekayaan: user.totalKekayaan,
                fotoProfil: user.fotoProfil,
              );
              final db = ref.read(databaseProvider);
              await db.updateUser(updatedUser);
              ref.invalidate(userProvider);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  // BOTTOM SHEET: Wallet Manager (Edit/Delete only)
  void _showWalletManager(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => const WalletManagerSheet(),
    );
  }

  // BOTTOM SHEET: Category Manager
  void _showCategoryManager(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => const CategoryManagerSheet(),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              ref.read(activePageProvider.notifier).setPage(0);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// WALLET MANAGER (Edit / Delete only - No Add)
// ============================================================
class WalletManagerSheet extends ConsumerWidget {
  const WalletManagerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wallets = ref.watch(walletProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.65,
      child: Column(
        children: [
          const Text('Edit / Hapus Dompet', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Untuk menambah dompet, gunakan tombol "Tambah" di Dashboard.',
              style: TextStyle(fontSize: 12, color: Colors.grey), textAlign: TextAlign.center),
          const Divider(height: 24),
          Expanded(
            child: wallets.when(
              data: (list) => list.isEmpty
                  ? const Center(child: Text('Belum ada dompet'))
                  : ListView.builder(
                      itemCount: list.length,
                      itemBuilder: (context, index) {
                        final w = list[index];
                        return ListTile(
                          leading: const Icon(Icons.wallet, color: Colors.blue),
                          title: Text(w.namaWallet, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text('Saldo: Rp ${w.saldo.toStringAsFixed(0)}'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Edit
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: Colors.blue),
                                tooltip: 'Edit',
                                onPressed: () => _showEditWalletDialog(context, ref, w),
                              ),
                              // Delete
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: 'Hapus',
                                onPressed: () async {
                                  final db = ref.read(databaseProvider);
                                  await db.deleteWallet(w.idWallet!);
                                  ref.read(walletProvider.notifier).refresh();
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ),
        ],
      ),
    );
  }

  void _showEditWalletDialog(BuildContext context, WidgetRef ref, wallet) {
    final nameController = TextEditingController(text: wallet.namaWallet);
    final balanceController = TextEditingController(text: wallet.saldo.toStringAsFixed(0));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Dompet'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nama Dompet', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: balanceController,
              decoration: const InputDecoration(labelText: 'Saldo (Rp)', border: OutlineInputBorder()),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              final updatedWallet = wallet.copyWith(
                namaWallet: nameController.text,
                saldo: double.tryParse(balanceController.text) ?? wallet.saldo,
              );
              final db = ref.read(databaseProvider);
              await db.updateWallet(updatedWallet);
              ref.read(walletProvider.notifier).refresh();
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CATEGORY MANAGER (View, Add, Edit, Delete)
// ============================================================
class CategoryManagerSheet extends ConsumerWidget {
  const CategoryManagerSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoryProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      height: MediaQuery.of(context).size.height * 0.75,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kelola Kategori', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle, color: Colors.blue, size: 30),
                onPressed: () => _showAddCategoryDialog(context, ref),
              ),
            ],
          ),
          const Divider(),
          Expanded(
            child: categories.when(
              data: (list) {
                final incomeList = list.where((c) => c.jenisArusKas == 'IN').toList();
                final outcomeList = list.where((c) => c.jenisArusKas == 'OUT').toList();

                return ListView(
                  children: [
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Pemasukan (IN)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                    ),
                    ...incomeList.map((c) => _buildCategoryTile(context, ref, c)),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Text('Pengeluaran (OUT)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    ),
                    ...outcomeList.map((c) => _buildCategoryTile(context, ref, c)),
                  ],
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTile(BuildContext context, WidgetRef ref, CategoryModel c) {
    final isIn = c.jenisArusKas == 'IN';
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isIn ? Colors.green[50] : Colors.red[50],
        child: Icon(
          isIn ? Icons.arrow_upward : Icons.arrow_downward,
          color: isIn ? Colors.green : Colors.red,
          size: 18,
        ),
      ),
      title: Text(c.namaKategori),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Edit
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: Colors.blue),
            tooltip: 'Edit',
            onPressed: () => _showEditCategoryDialog(context, ref, c),
          ),
          // Delete
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            tooltip: 'Hapus',
            onPressed: () async {
              final db = ref.read(databaseProvider);
              await db.deleteKategori(c.idKategori!);
              ref.invalidate(categoryProvider);
            },
          ),
        ],
      ),
    );
  }

  void _showEditCategoryDialog(BuildContext context, WidgetRef ref, CategoryModel c) {
    final nameController = TextEditingController(text: c.namaKategori);
    String selectedType = c.jenisArusKas;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Edit Kategori'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Kategori', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Jenis', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'IN', child: Text('Pemasukan (IN)')),
                  DropdownMenuItem(value: 'OUT', child: Text('Pengeluaran (OUT)')),
                ],
                onChanged: (val) => setState(() => selectedType = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                final updated = CategoryModel(
                  idKategori: c.idKategori,
                  namaKategori: nameController.text,
                  jenisArusKas: selectedType,
                );
                final db = ref.read(databaseProvider);
                await db.updateKategori(updated);
                ref.invalidate(categoryProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddCategoryDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    String selectedType = 'OUT';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Tambah Kategori Baru'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Nama Kategori', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedType,
                decoration: const InputDecoration(labelText: 'Jenis', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'IN', child: Text('Pemasukan (IN)')),
                  DropdownMenuItem(value: 'OUT', child: Text('Pengeluaran (OUT)')),
                ],
                onChanged: (val) => setState(() => selectedType = val!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            ElevatedButton(
              onPressed: () async {
                if (nameController.text.isEmpty) return;
                final newCat = CategoryModel(
                  namaKategori: nameController.text,
                  jenisArusKas: selectedType,
                );
                final db = ref.read(databaseProvider);
                await db.insertKategori(newCat);
                ref.invalidate(categoryProvider);
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Tambah'),
            ),
          ],
        ),
      ),
    );
  }
}

