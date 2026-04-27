import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BottomNav extends StatelessWidget {
  final int currentIndex;

  const BottomNav({super.key, required this.currentIndex});

  void _navigate(BuildContext context, int index) {
    final routes = ['/dashboard', '/alarm', '/history', '/settings'];
    if (index == currentIndex) return;
    Navigator.pushReplacementNamed(context, routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF132236) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05);
    final shadowColor =
        isDark ? Colors.black.withOpacity(0.30) : Colors.black.withOpacity(0.08);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: borderColor),
          boxShadow: [
            BoxShadow(
              color: shadowColor,
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: _NavItem(
                label: 'Dashboard',
                icon: Icons.grid_view_rounded,
                selected: currentIndex == 0,
                onTap: () => _navigate(context, 0),
              ),
            ),
            Expanded(
              child: _NavItem(
                label: 'Alarm',
                icon: Icons.notifications_active_rounded,
                selected: currentIndex == 1,
                onTap: () => _navigate(context, 1),
              ),
            ),
            Expanded(
              child: _NavItem(
                label: 'Riwayat',
                icon: Icons.history_rounded,
                selected: currentIndex == 2,
                onTap: () => _navigate(context, 2),
              ),
            ),
            Expanded(
              child: _NavItem(
                label: 'Pengaturan',
                icon: Icons.settings_rounded,
                selected: currentIndex == 3,
                onTap: () => _navigate(context, 3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final activeBg = isDark ? const Color(0xFF30445D) : const Color(0xFFFFF1F0);
    final activeColor = isDark ? Colors.white : AppTheme.primaryRed;
    final inactiveColor =
        isDark ? Colors.white.withOpacity(0.82) : const Color(0xFF667085);

    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? activeBg : Colors.transparent,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(
                icon,
                size: 24,
                color: selected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 8),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                color: selected ? activeColor : inactiveColor,
              ),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}