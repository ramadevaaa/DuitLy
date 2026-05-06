import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:duitly/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:duitly/features/analytics/presentation/screens/analytics_screen.dart';
import 'package:duitly/features/settings/presentation/screens/settings_screen.dart';
import 'package:duitly/features/chat/presentation/screens/chat_screen.dart';

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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: activePage,
        onTap: (index) => ref.read(activePageProvider.notifier).setPage(index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Beranda'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Analisis'),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: 'AI'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Pengaturan'),
        ],
      ),
    );
  }
}
