import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../theme/app_theme.dart';
import '../widgets/bottom_nav.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final DatabaseReference _historyRef = FirebaseDatabase.instance.ref(
    'history/device_1',
  );

  List<Map<String, dynamic>> historyList = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _listenHistory();
  }

  void _listenHistory() {
    _historyRef
        .limitToLast(30)
        .onValue
        .listen(
          (event) {
            final data = event.snapshot.value;

            if (data != null && data is Map) {
              final List<Map<String, dynamic>> tempList = [];

              data.forEach((key, value) {
                if (value is Map) {
                  tempList.add({
                    'id': key,
                    'suhu':
                        double.tryParse(value['suhu']?.toString() ?? '0') ??
                        0.0,
                    'kelembapan':
                        double.tryParse(
                          value['kelembapan']?.toString() ?? '0',
                        ) ??
                        0.0,
                    'asap': int.tryParse(value['asap']?.toString() ?? '0') ?? 0,
                    'api': value['api'] == true,
                    'buzzer': value['buzzer'] == true,
                    'kondisi': value['kondisi']?.toString() ?? 'AMAN',
                    'timestamp':
                        int.tryParse(value['timestamp']?.toString() ?? '0') ??
                        0,
                  });
                }
              });

              tempList.sort((a, b) {
                return (b['timestamp'] as int).compareTo(a['timestamp'] as int);
              });

              setState(() {
                historyList = tempList;
                isLoading = false;
              });
            } else {
              setState(() {
                historyList = [];
                isLoading = false;
              });
            }
          },
          onError: (error) {
            setState(() {
              historyList = [];
              isLoading = false;
            });
          },
        );
  }

  Color _getStatusColor(String status) {
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

  IconData _getStatusIcon(String status) {
    if (status == 'DARURAT') {
      return Icons.warning_rounded;
    } else if (status == 'WASPADA') {
      return Icons.report_problem_rounded;
    } else if (status == 'AMAN') {
      return Icons.check_circle_rounded;
    } else {
      return Icons.help_rounded;
    }
  }

  String _formatTimestamp(int timestamp) {
    if (timestamp <= 0) return '-';

    final DateTime date = DateTime.fromMillisecondsSinceEpoch(timestamp);

    final String day = date.day.toString().padLeft(2, '0');
    final String month = date.month.toString().padLeft(2, '0');
    final String year = date.year.toString();

    final String hour = date.hour.toString().padLeft(2, '0');
    final String minute = date.minute.toString().padLeft(2, '0');
    final String second = date.second.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute:$second';
  }

  Future<void> _clearHistory() async {
    await _historyRef.remove();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('History berhasil dihapus')));
    }
  }

  void _showClearConfirmation() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus History?'),
          content: const Text(
            'Semua data riwayat pembacaan sensor akan dihapus.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _clearHistory();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryRed,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
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

    return Scaffold(
      backgroundColor: pageBg,
      bottomNavigationBar: BottomNav(currentIndex: 2),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'History',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Riwayat pembacaan sensor, buzzer, dan kondisi',
                              style: TextStyle(
                                color: subTextColor,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: historyList.isEmpty
                            ? null
                            : _showClearConfirmation,
                        icon: const Icon(Icons.delete_rounded),
                        color: AppTheme.primaryRed,
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  if (historyList.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      ),
                      child: Column(
                        children: [
                          Icon(
                            Icons.history_rounded,
                            size: 60,
                            color: subTextColor,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Belum ada data history',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Data akan muncul setelah ESP32 mengirim riwayat ke Firebase.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: subTextColor, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  else
                    ...historyList.map((item) {
                      final String kondisi = item['kondisi'] as String;
                      final Color statusColor = _getStatusColor(kondisi);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 14),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 52,
                                height: 52,
                                decoration: BoxDecoration(
                                  color: statusColor.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _getStatusIcon(kondisi),
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      kondisi,
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTimestamp(
                                        item['timestamp'] as int,
                                      ),
                                      style: TextStyle(
                                        color: subTextColor,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Suhu: ${(item['suhu'] as double).toStringAsFixed(1)}°C',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Kelembapan: ${(item['kelembapan'] as double).toStringAsFixed(1)}%',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Asap: ${item['asap']} | Api: ${(item['api'] as bool) ? "Ya" : "Tidak"} | Buzzer: ${(item['buzzer'] as bool) ? "On" : "Off"}',
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
      ),
    );
  }
}
