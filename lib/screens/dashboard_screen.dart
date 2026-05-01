import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../theme/app_theme.dart';
import '../widgets/sensor_card.dart';
import '../widgets/bottom_nav.dart';
import '../services/alert_service.dart';
import '../services/alarm_service.dart';
import '../services/notification_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref(
    'monitoring/device_1',
  );
  final AlarmService _alarmService = AlarmService();

  StreamSubscription<DatabaseEvent>? _databaseSubscription;
  Timer? _onlineStatusTimer;

  double temperature = 0.0;
  double humidity = 0.0;
  int smokeValue = 0;
  int? lastUpdate;

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
    _startOnlineStatusTimer();
    _listenFirebaseData();
  }

  void _listenFirebaseData() {
    _databaseSubscription = _databaseRef.onValue.listen(
      (event) {
        final data = event.snapshot.value;

        if (!mounted) {
          return;
        }

        if (data != null && data is Map) {
          final String newStatus = _parseCondition(data['kondisi']);
          final int? newLastUpdate = _parseLastUpdate(data['lastUpdate']);

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

            lastUpdate = newLastUpdate;
            isLoading = false;
            isOnline = isDeviceOnline(newLastUpdate);
          });

          AlertService.handleStatusAlert(
            context: context,
            status: newStatus,
            mounted: mounted,
          );

          unawaited(NotificationService.handleCondition(newStatus));
          unawaited(_alarmService.handleCondition(newStatus));
        } else {
          setState(() {
            isLoading = false;
            isOnline = false;
            lastUpdate = null;
            status = 'OFFLINE';
            lcdLine1 = '-';
            lcdLine2 = 'Tidak ada data';
          });

          unawaited(NotificationService.handleCondition('AMAN'));
          unawaited(_alarmService.handleCondition('AMAN'));
        }
      },
      onError: (error) {
        if (!mounted) {
          return;
        }

        setState(() {
          isLoading = false;
          isOnline = false;
          lastUpdate = null;
          status = 'OFFLINE';
          lcdLine1 = '-';
          lcdLine2 = 'Gagal membaca data';
        });

        unawaited(NotificationService.handleCondition('AMAN'));
        unawaited(_alarmService.handleCondition('AMAN'));
      },
    );
  }

  void _startOnlineStatusTimer() {
    _onlineStatusTimer?.cancel();
    _onlineStatusTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _refreshDeviceOnlineStatus(),
    );
  }

  void _refreshDeviceOnlineStatus() {
    final bool newIsOnline = isDeviceOnline(lastUpdate);

    if (!mounted || newIsOnline == isOnline) {
      return;
    }

    setState(() {
      isOnline = newIsOnline;
    });
  }

  bool isDeviceOnline(int? lastUpdate) {
    if (lastUpdate == null || lastUpdate <= 0) {
      return false;
    }

    final int now = DateTime.now().millisecondsSinceEpoch;
    final int diff = now - lastUpdate;

    return diff <= 15000;
  }

  int? _parseLastUpdate(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    return int.tryParse(value.toString().trim());
  }

  String _parseCondition(dynamic value) {
    final String condition = value?.toString().trim().toUpperCase() ?? '';

    if (condition == 'WASPADA' ||
        condition == 'DARURAT' ||
        condition == 'AMAN') {
      return condition;
    }

    return 'AMAN';
  }

  @override
  void dispose() {
    _onlineStatusTimer?.cancel();
    unawaited(_databaseSubscription?.cancel());
    unawaited(_alarmService.dispose());
    super.dispose();
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
      return 'Darurat';
    } else if (smokeValue >= 2500) {
      return 'Waspada';
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final Color statusColor = _getStatusColor();

    final Color textColor = isDark
        ? const Color(0xFFF9FAFB)
        : AppTheme.darkText;

    final Color pageBg = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF6F7FB);

    final Color deviceBadgeColor = isOnline
        ? AppTheme.green
        : (isDark ? const Color(0xFF64748B) : AppTheme.primaryRed);

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
                        .withValues(alpha: 0.18),
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
                            color: Colors.white.withValues(alpha: 0.88),
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
                      color: deviceBadgeColor.withValues(
                        alpha: isDark ? 0.30 : 0.26,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: deviceBadgeColor.withValues(alpha: 0.72),
                      ),
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
                    statusColor.withValues(alpha: isDark ? 0.88 : 0.72),
                    statusColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(26),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withValues(alpha: 0.24),
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
                              CircularProgressIndicator(color: Colors.white),
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
                      color: Colors.white.withValues(alpha: 0.18),
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
              icon: Icons.water_drop_rounded,
              title: 'Kelembapan',
              value: '${humidity.toStringAsFixed(1)}%',
              iconColor: Colors.blue,
            ),

            SensorCard(
              icon: Icons.thermostat_rounded,
              title: 'Suhu',
              value: '${temperature.toStringAsFixed(1)}\u00B0C',
              iconColor: _getTemperatureColor(),
            ),
          ],
        ),
      ),
    );
  }
}
