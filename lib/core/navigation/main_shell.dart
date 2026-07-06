import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duitly/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:duitly/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:duitly/features/user/presentation/screens/profile_screen.dart';
import 'package:duitly/features/chat/presentation/screens/chat_screen.dart';
import 'package:duitly/features/transaction/presentation/widgets/add_transaction_sheet.dart';

class ActivePageNotifier extends Notifier<int> {
  @override
  int build() => 0;
  void setPage(int page) => state = page;
}

final activePageProvider = NotifierProvider<ActivePageNotifier, int>(
  () => ActivePageNotifier(),
);

class MainShell extends ConsumerWidget {
  const MainShell({super.key});

  void _showAddSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activePage = ref.watch(activePageProvider);

    // Index 2 (tengah) dikosongkan — FAB yang handle aksi "tambah"
    // Nav hanya 4 item: 0=Beranda, 1=Riwayat, 2=Laporan, 3=Akun
    const pages = [
      DashboardScreen(),
      AnalyticsScreen(),
      ChatScreen(), // dipakai sebagai "Laporan" (index 2 di pages)
      ProfileScreen(),
    ];

    // Mapping index nav (0..4, skip 2 tengah FAB) → page index
    // navIndex: 0→page0, 1→page1, (2=FAB), 3→page2, 4→page3
    int pageFromNav(int navIdx) {
      if (navIdx < 2) return navIdx;
      return navIdx - 1;
    }

    int navFromPage(int pageIdx) {
      if (pageIdx < 2) return pageIdx;
      return pageIdx + 1;
    }

    return Scaffold(
      extendBody:
          true, // body mengalir di balik nav bar (agar FAB terlihat melayang)
      body: pages[activePage],

      // FAB menonjol ke atas dari bottom nav hanya di Beranda (0) dan Riwayat (1)
      floatingActionButton: (activePage == 0 || activePage == 1)
          ? FloatingActionButton(
              onPressed: () => _showAddSheet(context),
              backgroundColor: const Color(0xFF1565C0),
              elevation: 4,
              shape: const CircleBorder(),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            )
          : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 12,
        shadowColor: Colors.black26,
        shape: (activePage == 0 || activePage == 1)
            ? const CircularNotchedRectangle()
            : null,
        notchMargin: 8,
        child: SizedBox(
          height: 54,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home,
                label: 'Beranda',
                navIndex: 0,
                currentNavIndex: navFromPage(activePage),
                onTap: () => ref
                    .read(activePageProvider.notifier)
                    .setPage(pageFromNav(0)),
              ),
              _NavItem(
                icon: Icons.history,
                activeIcon: Icons.history,
                label: 'Riwayat',
                navIndex: 1,
                currentNavIndex: navFromPage(activePage),
                onTap: () => ref
                    .read(activePageProvider.notifier)
                    .setPage(pageFromNav(1)),
              ),
              // Spacer untuk notch FAB hanya jika FAB aktif
              if (activePage == 0 || activePage == 1)
                const SizedBox(width: 48),
              _NavItem(
                icon: Icons.smart_toy_outlined,
                activeIcon: Icons.smart_toy,
                label: 'AI Agent',
                navIndex: 3,
                currentNavIndex: navFromPage(activePage),
                onTap: () => ref
                    .read(activePageProvider.notifier)
                    .setPage(pageFromNav(3)),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                label: 'Akun',
                navIndex: 4,
                currentNavIndex: navFromPage(activePage),
                onTap: () => ref
                    .read(activePageProvider.notifier)
                    .setPage(pageFromNav(4)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int navIndex;
  final int currentNavIndex;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.navIndex,
    required this.currentNavIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = navIndex == currentNavIndex;
    final color = isActive ? const Color(0xFF1565C0) : Colors.grey[500]!;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(isActive ? activeIcon : icon, color: color, size: 24),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
