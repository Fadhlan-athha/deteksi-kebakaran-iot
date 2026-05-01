import 'dart:async';
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
import 'services/alarm_service.dart';
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

class MyAppState extends State<MyApp> with WidgetsBindingObserver {
  final AlarmService _alarmService = AlarmService();
  final DatabaseReference _conditionRef = FirebaseDatabase.instance.ref(
    'monitoring/device_1/kondisi',
  );

  StreamSubscription<DatabaseEvent>? _conditionSubscription;
  ThemeMode _themeMode = ThemeMode.system;

  void changeTheme(ThemeMode mode) {
    setState(() {
      _themeMode = mode;
    });
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
    _listenConditionForForegroundAlarm();

    Future.microtask(() async {
      try {
        await NotificationService.configureFcmHandlers(
          onNotificationOpened: (_) =>
              _refreshLatestCondition(forceAlarmRestart: true),
        );
        await _refreshLatestCondition(forceAlarmRestart: true);
        await saveFcmToken();
      } catch (e) {
        debugPrint('Gagal menyiapkan FCM/alarm awal: $e');
      }
    });
  }

  void _listenConditionForForegroundAlarm() {
    _conditionSubscription = _conditionRef.onValue.listen(
      (event) {
        unawaited(_handleConditionValue(event.snapshot.value));
      },
      onError: (error) {
        debugPrint('Gagal membaca kondisi alarm foreground: $error');
        unawaited(_alarmService.handleCondition('AMAN'));
      },
    );
  }

  Future<void> _refreshLatestCondition({bool forceAlarmRestart = false}) async {
    try {
      final DataSnapshot snapshot = await _conditionRef.get();
      await _handleConditionValue(
        snapshot.value,
        forceAlarmRestart: forceAlarmRestart,
      );
    } catch (e) {
      debugPrint('Gagal refresh kondisi terbaru: $e');
      await _alarmService.handleCondition('AMAN');
    }
  }

  Future<void> _handleConditionValue(
    dynamic value, {
    bool forceAlarmRestart = false,
  }) async {
    await _alarmService.handleCondition(
      _normalizeCondition(value),
      force: forceAlarmRestart,
    );
  }

  String _normalizeCondition(dynamic value) {
    final String condition = value?.toString().trim().toUpperCase() ?? '';

    if (condition == 'WASPADA' || condition == 'DARURAT') {
      return condition;
    }

    if (condition == 'AMAN' || condition == 'NORMAL') {
      return 'AMAN';
    }

    return 'AMAN';
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_refreshLatestCondition(forceAlarmRestart: true));
    }

    // Saat app background, layar terkunci, atau layar mati, Android tidak
    // menjamin loop audio/getar Dart terus hidup. Jalur andal untuk kondisi
    // tersebut adalah FCM + notification channel bersuara dan bergetar.
    // Jika HP power off, force stop, atau app di-uninstall, notifikasi tidak
    // bisa diterima karena proses aplikasi/sistem penerima tidak berjalan.
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_conditionSubscription?.cancel());
    unawaited(_alarmService.dispose());
    super.dispose();
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
