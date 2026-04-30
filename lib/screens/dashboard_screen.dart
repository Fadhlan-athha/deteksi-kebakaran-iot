import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../theme/app_theme.dart';
import '../widgets/sensor_card.dart';
import '../widgets/bottom_nav.dart';
import '../services/alert_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseReference _databaseRef =
      FirebaseDatabase.instance.ref('monitoring/device_1');

  double temperature = 0.0;
  double humidity = 0.0;
  int smokeValue = 0;

  bool fireDetected = false;
  bool buzzerOn = false;

  String status = 'MEMUAT';
  String lcdLine1 = '-';
  String lcdLine2 = '-';

  bool isLoading = true;
  bool isOnline = false;

  @override
  void initState() {
    super.initState();
    _listenFirebaseData();
  }

  void _listenFirebaseData() {
    _databaseRef.onValue.listen(
      (event) async {
        final data = event.snapshot.value;

        if (data != null && data is Map) {
          final String newStatus = data['kondisi']?.toString() ?? 'AMAN';

          setState(() {
            temperature =
                double.tryParse(data['suhu']?.toString() ?? '0') ?? 0.0;

            humidity =
                double.tryParse(data['kelembapan']?.toString() ?? '0') ?? 0.0;

            smokeValue = int.tryParse(data['asap']?.toString() ?? '0') ?? 0;

            fireDetected = data['api'] == true;
            buzzerOn = data['buzzer'] == true;

            status = newStatus;

            lcdLine1 = data['lcdLine1']?.toString() ?? '-';
            lcdLine2 = data['lcdLine2']?.toString() ?? '-';

            isLoading = false;
            isOnline = true;
          });

          await AlertService.handleStatusAlert(
            context: context,
            status: newStatus,
            mounted: mounted,
          );
        } else {
          setState(() {
            isLoading = false;
            isOnline = false;
            status = 'OFFLINE';
            lcdLine1 = '-';
            lcdLine2 = 'Tidak ada data';
          });
        }
      },
      onError: (error) {
        setState(() {
          isLoading = false;
          isOnline = false;
          status = 'OFFLINE';
          lcdLine1 = '-';
          lcdLine2 = 'Gagal membaca data';
        });
      },
    );
  }

  Color _getStatusColor() {
    if (status == 'DARURAT') {
      return AppTheme.primaryRed;
    } else if (status == 'WASPADA') {
      return AppTheme.orange;
    } else if (status == 'AMAN') {
      return AppTheme.green;
    } else {
      return Colors.grey;
    }
  }

  IconData _getStatusIcon() {
    if (status == 'DARURAT') {
      return Icons.warning_rounded;
    } else if (status == 'WASPADA') {
      return Icons.report_problem_rounded;
    } else if (status == 'AMAN') {
      return Icons.check_circle_rounded;
    } else {
      return Icons.wifi_off_rounded;
    }
  }

  String _getStatusDescription() {
    if (status == 'DARURAT') {
      return 'Bahaya kebakaran terdeteksi. Segera lakukan pengecekan.';
    } else if (status == 'WASPADA') {
      return 'Suhu dan asap melewati batas waspada.';
    } else if (status == 'AMAN') {
      return 'Semua sensor dalam kondisi normal.';
    } else {
      return 'Perangkat belum terhubung atau belum mengirim data.';
    }
  }

  String _getSmokeStatus() {
    if (smokeValue >= 3500) {
      return 'Tinggi';
    } else if (smokeValue >= 2500) {
      return 'Meningkat';
    } else {
      return 'Normal';
    }
  }

  Color _getSmokeColor(bool isDark) {
    if (smokeValue >= 3500) {
      return AppTheme.primaryRed;
    } else if (smokeValue >= 2500) {
      return AppTheme.orange;
    } else {
      return isDark ? const Color(0xFFCBD5E1) : Colors.grey;
    }
  }

  Color _getTemperatureColor() {
    if (temperature >= 45) {
      return AppTheme.primaryRed;
    } else if (temperature >= 35) {
      return AppTheme.orange;
    } else {
      return AppTheme.green;
    }
  }

  String _getFireStatusText() {
    return fireDetected ? 'Terdeteksi' : 'Tidak Terdeteksi';
  }

  String _getBuzzerStatusText() {
    return buzzerOn ? 'Menyala' : 'Mati';
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color statusColor = _getStatusColor();

    final Color textColor =
        isDark ? const Color(0xFFF9FAFB) : AppTheme.darkText;

    final Color subTextColor = isDark ? Colors.white70 : AppTheme.greyText;

    final Color pageBg =
        isDark ? const Color(0xFF0F172A) : const Color(0xFFF6F7FB);

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
                      children: [
                        Icon(
                          isOnline
                              ? Icons.wifi_rounded
                              : Icons.wifi_off_rounded,
                          size: 14,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: const TextStyle(
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
                    child: isLoading
                        ? const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kondisi Saat Ini',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 12),
                              CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            ],
                          )
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kondisi Saat Ini',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
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
                                _getStatusDescription(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  height: 1.3,
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
                      _getStatusIcon(),
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
              value: _getFireStatusText(),
              iconColor: AppTheme.primaryRed,
              onTap: fireDetected
                  ? () => Navigator.pushNamed(context, '/alarm')
                  : null,
            ),

            SensorCard(
              icon: Icons.cloud_rounded,
              title: 'Status Asap',
              value: '${_getSmokeStatus()} ($smokeValue)',
              iconColor: _getSmokeColor(isDark),
            ),

            SensorCard(
              icon: Icons.volume_up_rounded,
              title: 'Status Buzzer',
              value: _getBuzzerStatusText(),
              iconColor: buzzerOn ? AppTheme.primaryRed : Colors.grey,
            ),

            SensorCard(
              icon: Icons.display_settings_rounded,
              title: 'LCD I2C',
              value: '$lcdLine1 | $lcdLine2',
              iconColor: Colors.indigo,
            ),

            SensorCard(
              icon: Icons.water_drop_rounded,
              title: 'Kelembapan',
              value: '${humidity.toStringAsFixed(1)}%',
              iconColor: Colors.blue,
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
                        color: _getTemperatureColor().withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.thermostat_rounded,
                        color: _getTemperatureColor(),
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
                            style: TextStyle(
                              color: subTextColor,
                              fontSize: 14,
                            ),
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
                              value: (temperature / 50).clamp(0.0, 1.0),
                              minHeight: 9,
                              color: _getTemperatureColor(),
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

            const SizedBox(height: 8),

            Text(
              'Catatan: getar dan popup aktif saat status berubah menjadi WASPADA atau DARURAT.',
              style: TextStyle(
                color: subTextColor,
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}