import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/sensor_card.dart';
import '../widgets/bottom_nav.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const bool fireDetected = false;
    const bool smokeHigh = false;
    const double temperature = 29.0;

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final String status = fireDetected
        ? 'DARURAT'
        : smokeHigh || temperature >= 35
        ? 'WASPADA'
        : 'AMAN';

    final Color statusColor = fireDetected
        ? AppTheme.primaryRed
        : smokeHigh || temperature >= 35
        ? AppTheme.orange
        : AppTheme.green;

    final Color textColor = isDark
        ? const Color(0xFFF9FAFB)
        : AppTheme.darkText;
    final Color subTextColor = isDark ? Colors.white70 : AppTheme.greyText;
    final Color pageBg = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF6F7FB);

    return Scaffold(
      backgroundColor: pageBg,
      bottomNavigationBar: BottomNav(currentIndex: 0),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? const [Color(0xFF1E293B), Color(0xFF24364E)]
                      : const [Color(0xFFFF6A5C), Color(0xFFE94B3C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: (isDark ? Colors.black : AppTheme.primaryRed)
                        .withOpacity(0.18),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Dashboard',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Sistem Deteksi Dini Kebakaran',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.88),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: const [
                        Icon(Icons.wifi_rounded, size: 14, color: Colors.white),
                        SizedBox(width: 6),
                        Text(
                          'Online',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor.withOpacity(isDark ? 0.88 : 0.72),
                    statusColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.24),
                    blurRadius: 22,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Kondisi Saat Ini',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          status,
                          style: const TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          fireDetected
                              ? 'Bahaya kebakaran terdeteksi'
                              : smokeHigh || temperature >= 35
                              ? 'Asap atau suhu mulai meningkat'
                              : 'Semua sensor dalam kondisi normal',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeOutBack,
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      fireDetected
                          ? Icons.warning_rounded
                          : Icons.check_circle_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            Text(
              'Status Sensor',
              style: TextStyle(
                color: textColor,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),

            SensorCard(
              icon: Icons.local_fire_department_rounded,
              title: 'Status Api',
              value: fireDetected ? 'Terdeteksi' : 'Tidak Terdeteksi',
              iconColor: AppTheme.primaryRed,
              onTap: fireDetected
                  ? () => Navigator.pushNamed(context, '/alarm')
                  : null,
            ),

            SensorCard(
              icon: Icons.cloud_rounded,
              title: 'Status Asap',
              value: smokeHigh ? 'Terdeteksi' : 'Tidak Terdeteksi',
              iconColor: isDark ? const Color(0xFFCBD5E1) : Colors.grey,
            ),

            Card(
              margin: const EdgeInsets.only(bottom: 14),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppTheme.green.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.thermostat_rounded,
                        color: AppTheme.green,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Suhu',
                            style: TextStyle(color: subTextColor, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${temperature.toStringAsFixed(1)}°C',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: LinearProgressIndicator(
                              value: temperature / 50,
                              minHeight: 9,
                              color: AppTheme.green,
                              backgroundColor: isDark
                                  ? Colors.white.withOpacity(0.08)
                                  : Colors.grey.shade200,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
