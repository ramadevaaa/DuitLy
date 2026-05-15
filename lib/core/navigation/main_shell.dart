import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duitly/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:duitly/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:duitly/features/settings/presentation/screens/settings_screen.dart';
import 'package:duitly/features/chat/presentation/screens/chat_screen.dart';
import 'package:duitly/features/transaction/presentation/widgets/add_transaction_sheet.dart';

// Provider untuk track halaman aktif (Riverpod v3 compatible)
class ActivePageNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void setPage(int page) => state = page;
}

final activePageProvider = NotifierProvider<ActivePageNotifier, int>(() => ActivePageNotifier());

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePage = ref.watch(activePageProvider);

    final pages = const [
      DashboardScreen(),
      AnalyticsScreen(),
      ChatScreen(),
      SettingsScreen(),
    ];

    return Scaffold(
      body: pages[activePage],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -5)),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home, 'Beranda', 0, ref, activePage),
                _buildNavItem(Icons.history, 'Riwayat', 1, ref, activePage),
                
                // Tombol Tambah menyatu dengan bar (tidak melayang)
                InkWell(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
                      ),
                      builder: (context) => const AddTransactionSheet(),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 28),
                  ),
                ),
                
                _buildNavItem(Icons.smart_toy, 'AI', 2, ref, activePage),
                _buildNavItem(Icons.settings, 'Pengaturan', 3, ref, activePage),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, WidgetRef ref, int activePage) {
    final isSelected = activePage == index;
    final color = isSelected ? Colors.blue : Colors.grey;
    return InkWell(
      onTap: () => ref.read(activePageProvider.notifier).setPage(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          Text(label, style: TextStyle(color: color, fontSize: 10)),
        ],
      ),
    );
  }
}
