import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';
import 'screens/dashboard_screen.dart';
import 'screens/alarm_screen.dart';
import 'screens/history_screen.dart';
import 'screens/settings_screen.dart';
import 'theme/app_theme.dart';
import 'services/alert_service.dart';
import 'services/notification_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  DartPluginRegistrant.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  await NotificationService.handleFcmMessage(message);

  debugPrint('Background message: ${message.messageId}');
}

Future<void> saveFcmToken() async {
  try {
    final FirebaseMessaging messaging = FirebaseMessaging.instance;

    await messaging.setAutoInitEnabled(true);
    await NotificationService.requestNotificationPermission();
    await NotificationService.subscribeToAlertTopic();

    // Ini untuk mengecek apakah aplikasi bisa menulis ke Firebase.
    await FirebaseDatabase.instance.ref('tokens/device_1').update({
      'status': 'mencoba mengambil token',
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });

    final String? token = await messaging.getToken().timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        debugPrint('FCM token timeout');
        return null;
      },
    );

    if (token != null) {
      await FirebaseDatabase.instance.ref('tokens/device_1').set({
        'token': token,
        'status': 'token berhasil tersimpan',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('FCM Token tersimpan: $token');
    } else {
      await FirebaseDatabase.instance.ref('tokens/device_1').update({
        'token': '',
        'status': 'token null atau gagal diambil',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('FCM Token null');
    }

    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      await FirebaseDatabase.instance.ref('tokens/device_1').set({
        'token': newToken,
        'status': 'token diperbarui',
        'updatedAt': DateTime.now().millisecondsSinceEpoch,
      });

      debugPrint('FCM Token diperbarui: $newToken');
    });
  } catch (e) {
    await FirebaseDatabase.instance.ref('tokens/device_1').update({
      'token': '',
      'status': 'gagal mengambil token',
      'error': e.toString(),
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    });

    debugPrint('Gagal mengambil FCM token: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  await AlertService.init();
  await NotificationService.init();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static MyAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<MyAppState>();
  }

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void changeTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  void initState() {
    super.initState();

    Future.microtask(() async {
      try {
        await saveFcmToken();
      } finally {
        await NotificationService.configureFcmHandlers();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Deteksi Kebakaran IoT',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      initialRoute: '/dashboard',
      routes: {
        '/': (context) => const DashboardScreen(),
        '/dashboard': (context) => const DashboardScreen(),
        '/alarm': (context) => const AlarmScreen(),
        '/history': (context) => const HistoryScreen(),
        '/settings': (context) => const SettingsScreen(),
      },
    );
  }
}
