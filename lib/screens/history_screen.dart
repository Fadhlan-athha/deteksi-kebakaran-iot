import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final textColor =
        isDark ? const Color(0xFFF9FAFB) : AppTheme.darkText;
    final subTextColor =
        isDark ? Colors.white70 : AppTheme.greyText;
    final pageBg =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F7FB);

    final items = [
      ('Asap Normal', '10:10 WIB', 'Aman', AppTheme.green),
      ('Suhu Meningkat', '10:20 WIB', 'Waspada', AppTheme.orange),
      ('Status Waspada', '10:25 WIB', 'Waspada', AppTheme.orange),
      ('Api Terdeteksi', '10:35 WIB', 'Darurat', AppTheme.primaryRed),
      ('Status Darurat', '10:35 WIB', 'Darurat', AppTheme.primaryRed),
    ];

    return Scaffold(
      backgroundColor: pageBg,
      bottomNavigationBar: BottomNav(currentIndex: 2),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
          children: [
            Text(
              'Riwayat Kejadian',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: textColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Catatan aktivitas sensor dan notifikasi',
              style: TextStyle(
                color: subTextColor,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),

            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: const [
                _FilterChip('Semua', true),
                _FilterChip('Aman', false),
                _FilterChip('Waspada', false),
                _FilterChip('Darurat', false),
              ],
            ),

            const SizedBox(height: 18),

            ...items.map((item) {
              return _HistoryCard(
                title: item.$1,
                time: item.$2,
                status: item.$3,
                color: item.$4,
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String title;
  final String time;
  final String status;
  final Color color;

  const _HistoryCard({
    required this.title,
    required this.time,
    required this.status,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cardBg = isDark ? const Color(0xFF172131) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04);
    final titleColor = isDark ? Colors.white : AppTheme.darkText;
    final timeColor = isDark ? Colors.white70 : AppTheme.greyText;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: color.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: titleColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  time,
                  style: TextStyle(
                    color: timeColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Text(
              status,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;

  const _FilterChip(this.label, this.active);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeBg = AppTheme.primaryRed;
    final inactiveBg = isDark ? Colors.white : Colors.white;
    final activeText = Colors.white;
    final inactiveText = const Color(0xFF667085);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: active ? activeBg : inactiveBg,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? activeText : inactiveText,
          fontWeight: FontWeight.w700,
          fontSize: 15,
        ),
      ),
    );
  }
}