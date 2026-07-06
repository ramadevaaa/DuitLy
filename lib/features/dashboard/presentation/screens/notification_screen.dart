import 'package:flutter/material.dart';

const _kPrimary = Color(0xFF1565C0);
const _kPrimaryLight = Color(0xFF1976D2);

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  // Dummy notifications — in a real app these would come from a provider
  static final List<_NotifData> _notifications = [
    _NotifData(
      title: 'Selamat Datang di DuitLy! 🎉',
      body: 'Mulai kelola keuangan Anda dengan lebih cerdas bersama DuitLy.',
      icon: Icons.celebration_outlined,
      color: Color(0xFF1565C0),
      time: 'Baru saja',
      isRead: false,
    ),
    _NotifData(
      title: 'Tips Keuangan',
      body: 'Coba catat setiap pengeluaran harianmu untuk melihat pola konsumsimu.',
      icon: Icons.lightbulb_outline,
      color: Color(0xFFF57C00),
      time: '1 jam lalu',
      isRead: false,
    ),
    _NotifData(
      title: 'Fitur Scan Struk',
      body: 'Gunakan fitur scan struk untuk mencatat transaksi secara otomatis menggunakan AI.',
      icon: Icons.document_scanner_outlined,
      color: Color(0xFF00897B),
      time: 'Kemarin',
      isRead: true,
    ),
    _NotifData(
      title: 'DuitLy AI Siap Membantu',
      body: 'Tanyakan apapun seputar keuangan Anda ke DuitLy AI di tab AI Agent.',
      icon: Icons.auto_awesome_outlined,
      color: Color(0xFF7B1FA2),
      time: '2 hari lalu',
      isRead: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: CustomScrollView(
        slivers: [
          // ── Header ──
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_kPrimary, _kPrimaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Notifikasi',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      // Badge count
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          '2 baru',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── List ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, i) {
                  final n = _notifications[i];
                  return _NotifCard(data: n);
                },
                childCount: _notifications.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifData {
  final String title;
  final String body;
  final IconData icon;
  final Color color;
  final String time;
  final bool isRead;

  const _NotifData({
    required this.title,
    required this.body,
    required this.icon,
    required this.color,
    required this.time,
    required this.isRead,
  });
}

class _NotifCard extends StatelessWidget {
  final _NotifData data;
  const _NotifCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: data.isRead
            ? null
            : Border.all(color: _kPrimary.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: data.color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(data.icon, color: data.color, size: 22),
            ),
            const SizedBox(width: 12),
            // Text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          data.title,
                          style: TextStyle(
                            fontWeight: data.isRead ? FontWeight.w500 : FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (!data.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _kPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.body,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    data.time,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
