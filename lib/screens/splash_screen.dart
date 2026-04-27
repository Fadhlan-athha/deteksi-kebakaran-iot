import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/dashboard');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        color: const Color(0xFFFFFBFB),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.local_fire_department,
              size: 120,
              color: AppTheme.primaryRed,
            ),
            const SizedBox(height: 20),
            const Text(
              'Fire Detection',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: AppTheme.darkText,
              ),
            ),
            const Text(
              'IoT',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w400,
                color: AppTheme.greyText,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Monitoring Api, Asap, dan Suhu\nsecara real-time',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.greyText,
              ),
            ),
            const SizedBox(height: 48),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                4,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: index == 0 ? Colors.grey : Colors.grey.shade300,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              'Memuat sistem...',
              style: TextStyle(
                fontSize: 15,
                color: AppTheme.greyText,
              ),
            ),
          ],
        ),
      ),
    );
  }
}