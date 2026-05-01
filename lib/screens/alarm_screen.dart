import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';

class AlarmScreen extends StatefulWidget {
  const AlarmScreen({super.key});

  @override
  State<AlarmScreen> createState() => _AlarmScreenState();
}

class _AlarmScreenState extends State<AlarmScreen> {
  final DatabaseReference _databaseRef = FirebaseDatabase.instance.ref(
    'monitoring/device_1',
  );

  double temperature = 0.0;
  int smokeValue = 0;
  bool fireDetected = false;
  String status = 'MEMUAT';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _listenAlarmData();
  }

  void _listenAlarmData() {
    _databaseRef.onValue.listen((event) {
      final data = event.snapshot.value;

      if (data != null && data is Map) {
        setState(() {
          temperature = double.tryParse(data['suhu']?.toString() ?? '0') ?? 0.0;
          smokeValue = int.tryParse(data['asap']?.toString() ?? '0') ?? 0;
          fireDetected = data['api'] == true;
          status = data['kondisi']?.toString() ?? 'AMAN';
          isLoading = false;
        });
      } else {
        setState(() {
          status = 'OFFLINE';
          isLoading = false;
        });
      }
    });
  }

  Color _getAlarmColor() {
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

  String _getAlarmMessage() {
    if (status == 'DARURAT') {
      return 'Segera lakukan pengecekan. Sistem mendeteksi kondisi berbahaya.';
    } else if (status == 'WASPADA') {
      return 'Perhatikan kondisi ruangan. Suhu atau asap mulai meningkat.';
    } else if (status == 'AMAN') {
      return 'Tidak ada alarm aktif. Kondisi ruangan aman.';
    } else {
      return 'Perangkat belum terhubung atau belum mengirim data.';
    }
  }

  IconData _getAlarmIcon() {
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

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF6F7FB);
    final Color textColor = isDark
        ? const Color(0xFFF9FAFB)
        : AppTheme.darkText;
    final Color subTextColor = isDark ? Colors.white70 : AppTheme.greyText;
    final Color alarmColor = _getAlarmColor();

    return Scaffold(
      backgroundColor: pageBg,
      bottomNavigationBar: const BottomNav(currentIndex: 1),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    'Alarm',
                    style: TextStyle(
                      color: textColor,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Status peringatan dari sistem deteksi kebakaran',
                    style: TextStyle(color: subTextColor, fontSize: 14),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: alarmColor,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: alarmColor.withValues(alpha: 0.28),
                          blurRadius: 22,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(_getAlarmIcon(), color: Colors.white, size: 78),
                        const SizedBox(height: 18),
                        Text(
                          status,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _getAlarmMessage(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  _InfoTile(
                    title: 'Status Api',
                    value: fireDetected ? 'Terdeteksi' : 'Tidak Terdeteksi',
                    icon: Icons.local_fire_department_rounded,
                    color: AppTheme.primaryRed,
                  ),
                  _InfoTile(
                    title: 'Nilai Asap',
                    value: smokeValue.toString(),
                    icon: Icons.cloud_rounded,
                    color: Colors.grey,
                  ),
                  _InfoTile(
                    title: 'Suhu',
                    value: '${temperature.toStringAsFixed(1)}°C',
                    icon: Icons.thermostat_rounded,
                    color: AppTheme.green,
                  ),
                ],
              ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoTile({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color textColor = isDark
        ? const Color(0xFFF9FAFB)
        : AppTheme.darkText;
    final Color subTextColor = isDark ? Colors.white70 : AppTheme.greyText;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withValues(alpha: 0.12),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: TextStyle(color: subTextColor)),
        trailing: Text(
          value,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
