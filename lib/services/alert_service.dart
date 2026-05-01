import 'package:flutter/material.dart';

class AlertService {
  static String _lastStatus = 'AMAN';
  static bool _isDialogShowing = false;

  static Future<void> init() async {
    // Untuk sementara kosong.
    // Popup tidak butuh initialization khusus.
    // Alarm suara dan getar kontinu ditangani oleh AlarmService.
    // Notifikasi saat app tertutup akan ditangani oleh FCM + Cloud Function.
  }

  static void handleStatusAlert({
    required BuildContext context,
    required String status,
    required bool mounted,
  }) {
    if (status == _lastStatus) {
      return;
    }

    _lastStatus = status;

    if (status == 'WASPADA') {
      if (mounted) {
        showPopup(
          context: context,
          title: 'WASPADA',
          message: 'Suhu dan asap melewati batas waspada.',
          color: Colors.orange,
          icon: Icons.report_problem_rounded,
        );
      }
    } else if (status == 'DARURAT') {
      if (mounted) {
        showPopup(
          context: context,
          title: 'DARURAT',
          message: 'Kondisi kebakaran terdeteksi. Segera lakukan pengecekan.',
          color: Colors.red,
          icon: Icons.warning_rounded,
        );
      }
    }
  }

  static void showPopup({
    required BuildContext context,
    required String title,
    required String message,
    required Color color,
    required IconData icon,
  }) {
    if (_isDialogShowing) {
      return;
    }

    _isDialogShowing = true;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          icon: Icon(icon, color: color, size: 48),
          title: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
          content: Text(message, textAlign: TextAlign.center),
          actions: [
            TextButton(
              onPressed: () {
                _isDialogShowing = false;
                Navigator.pop(context);
              },
              child: const Text('Mengerti'),
            ),
          ],
        );
      },
    ).then((_) {
      _isDialogShowing = false;
    });
  }
}
