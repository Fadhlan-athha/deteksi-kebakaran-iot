import 'package:flutter_test/flutter_test.dart';

import 'package:fire_detection_iot/services/notification_service.dart';

void main() {
  test('FCM alert topic matches the device alert topic', () {
    expect(NotificationService.alertTopic, 'device_1_alerts');
  });
}
