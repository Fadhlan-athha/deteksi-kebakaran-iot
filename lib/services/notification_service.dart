import 'dart:typed_data';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static const String alertTopic = 'device_1_alerts';

  static const String _conditionAman = 'AMAN';
  static const String _conditionNormal = 'NORMAL';
  static const String _conditionWaspada = 'WASPADA';
  static const String _conditionDarurat = 'DARURAT';

  static const String _warningChannelId = 'fire_warning_channel';
  static const String _warningChannelName = 'Fire Warning';
  static const String _emergencyChannelId = 'fire_emergency_channel';
  static const String _emergencyChannelName = 'Fire Emergency';
  static const String _safeChannelId = 'fire_safe_channel';
  static const String _safeChannelName = 'Fire Safe';

  static const int _warningNotificationId = 1001;
  static const int _emergencyNotificationId = 1002;
  static const int _safeNotificationId = 1003;

  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static bool _isInitialized = false;
  static bool _fcmHandlersConfigured = false;
  static String? _lastCondition;

  static final Int64List _warningVibrationPattern = Int64List.fromList(
    const <int>[0, 500, 700, 500],
  );

  static final Int64List _emergencyVibrationPattern = Int64List.fromList(
    const <int>[0, 1000, 300, 1000, 300, 1000],
  );

  static Future<void> init() async {
    if (_isInitialized) {
      return;
    }

    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings darwinSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: androidSettings,
          iOS: darwinSettings,
          macOS: darwinSettings,
        );

    await _plugin.initialize(settings: initializationSettings);
    await setupNotificationChannels();

    _isInitialized = true;
  }

  static Future<void> setupNotificationChannels() async {
    final AndroidFlutterLocalNotificationsPlugin? androidPlugin = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidPlugin == null) {
      return;
    }

    const RawResourceAndroidNotificationSound warningSound =
        RawResourceAndroidNotificationSound('alarm_waspada');

    const RawResourceAndroidNotificationSound emergencySound =
        RawResourceAndroidNotificationSound('alarm_darurat');

    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        _warningChannelId,
        _warningChannelName,
        description: 'Notifikasi peringatan saat kondisi WASPADA.',
        importance: Importance.high,
        playSound: true,
        sound: warningSound,
        enableVibration: true,
        vibrationPattern: _warningVibrationPattern,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );

    await androidPlugin.createNotificationChannel(
      AndroidNotificationChannel(
        _emergencyChannelId,
        _emergencyChannelName,
        description: 'Notifikasi urgent saat kondisi DARURAT.',
        importance: Importance.max,
        playSound: true,
        sound: emergencySound,
        enableVibration: true,
        vibrationPattern: _emergencyVibrationPattern,
        audioAttributesUsage: AudioAttributesUsage.alarm,
      ),
    );

    const AndroidNotificationChannel safeChannel = AndroidNotificationChannel(
      _safeChannelId,
      _safeChannelName,
      description: 'Notifikasi saat kondisi kembali AMAN.',
      importance: Importance.defaultImportance,
    );

    await androidPlugin.createNotificationChannel(safeChannel);
  }

  static Future<void> requestNotificationPermission() async {
    await FirebaseMessaging.instance.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();

    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    await _plugin
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<void> subscribeToAlertTopic() async {
    await FirebaseMessaging.instance.subscribeToTopic(alertTopic);
  }

  static Future<void> configureFcmHandlers() async {
    if (_fcmHandlersConfigured) {
      return;
    }

    _fcmHandlersConfigured = true;

    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    FirebaseMessaging.onMessage.listen(handleFcmMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(handleFcmMessageOpenedApp);

    final RemoteMessage? initialMessage = await FirebaseMessaging.instance
        .getInitialMessage();

    if (initialMessage != null) {
      await handleFcmMessageOpenedApp(initialMessage);
    }
  }

  static Future<void> handleFcmMessage(RemoteMessage message) async {
    await init();

    final String condition = _conditionFromMessage(message);
    await handleCondition(condition);
  }

  static Future<void> handleFcmMessageOpenedApp(RemoteMessage message) async {
    await init();

    final String condition = _conditionFromMessage(message);

    if (condition == _conditionWaspada || condition == _conditionDarurat) {
      _lastCondition = condition;
    }
  }

  static Future<void> handleCondition(String kondisi) async {
    await init();

    final String condition = _normalizeCondition(kondisi);

    if (_lastCondition == condition) {
      return;
    }

    final String? previousCondition = _lastCondition;
    _lastCondition = condition;

    if (condition == _conditionWaspada) {
      await showWaspadaNotification();
    } else if (condition == _conditionDarurat) {
      await showDaruratNotification();
    } else {
      await _cancelActiveAlarmNotifications();

      if (previousCondition == _conditionWaspada ||
          previousCondition == _conditionDarurat) {
        await showAmanNotification();
      }
    }
  }

  static Future<void> showWaspadaNotification() async {
    await _plugin.cancel(id: _emergencyNotificationId);
    await _plugin.cancel(id: _safeNotificationId);

    await _plugin.show(
      id: _warningNotificationId,
      title: 'Peringatan Waspada',
      body: 'Kondisi sensor menunjukkan status WASPADA. Segera periksa lokasi.',
      notificationDetails: NotificationDetails(
        android: _androidWarningDetails(),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: _conditionWaspada,
    );
  }

  static Future<void> showDaruratNotification() async {
    await _plugin.cancel(id: _warningNotificationId);
    await _plugin.cancel(id: _safeNotificationId);

    await _plugin.show(
      id: _emergencyNotificationId,
      title: 'DARURAT Kebakaran',
      body: 'Kondisi DARURAT terdeteksi! Segera lakukan tindakan.',
      notificationDetails: NotificationDetails(
        android: _androidEmergencyDetails(),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: _conditionDarurat,
    );
  }

  static Future<void> showAmanNotification() async {
    await _plugin.show(
      id: _safeNotificationId,
      title: 'Kondisi Aman',
      body: 'Status perangkat kembali AMAN.',
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _safeChannelId,
          _safeChannelName,
          channelDescription: 'Notifikasi saat kondisi kembali AMAN.',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          playSound: true,
          enableVibration: true,
          visibility: NotificationVisibility.public,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
        macOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: _conditionAman,
    );
  }

  static AndroidNotificationDetails _androidWarningDetails() {
    const RawResourceAndroidNotificationSound sound =
        RawResourceAndroidNotificationSound('alarm_waspada');

    return AndroidNotificationDetails(
      _warningChannelId,
      _warningChannelName,
      channelDescription: 'Notifikasi peringatan saat kondisi WASPADA.',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
      sound: sound,
      enableVibration: true,
      vibrationPattern: _warningVibrationPattern,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ticker: 'Peringatan Waspada',
    );
  }

  static AndroidNotificationDetails _androidEmergencyDetails() {
    const RawResourceAndroidNotificationSound sound =
        RawResourceAndroidNotificationSound('alarm_darurat');

    return AndroidNotificationDetails(
      _emergencyChannelId,
      _emergencyChannelName,
      channelDescription: 'Notifikasi urgent saat kondisi DARURAT.',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      sound: sound,
      enableVibration: true,
      vibrationPattern: _emergencyVibrationPattern,
      audioAttributesUsage: AudioAttributesUsage.alarm,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      fullScreenIntent: true,
      ticker: 'DARURAT Kebakaran',
    );
  }

  static String _conditionFromMessage(RemoteMessage message) {
    final String? dataCondition =
        message.data['kondisi']?.toString() ??
        message.data['condition']?.toString() ??
        message.data['status']?.toString();

    if (dataCondition != null && dataCondition.trim().isNotEmpty) {
      return dataCondition;
    }

    final String title = message.notification?.title?.toUpperCase() ?? '';

    if (title.contains(_conditionDarurat)) {
      return _conditionDarurat;
    }

    if (title.contains(_conditionWaspada)) {
      return _conditionWaspada;
    }

    return _conditionAman;
  }

  static String _normalizeCondition(String kondisi) {
    final String condition = kondisi.trim().toUpperCase();

    if (condition == _conditionWaspada || condition == _conditionDarurat) {
      return condition;
    }

    if (condition == _conditionAman || condition == _conditionNormal) {
      return _conditionAman;
    }

    return _conditionAman;
  }

  static Future<void> _cancelActiveAlarmNotifications() async {
    await _plugin.cancel(id: _warningNotificationId);
    await _plugin.cancel(id: _emergencyNotificationId);
  }
}
