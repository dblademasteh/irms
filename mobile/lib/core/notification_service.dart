import 'package:flutter/services.dart';
import 'notification_service_stub.dart'
    if (dart.library.js_interop) 'notification_service_web.dart';

class NotificationService {
  static void notifyEmergencyBroadcast({required String author, required String message}) {
    try {
      SystemSound.play(SystemSoundType.alert);
      HapticFeedback.heavyImpact();
    } catch (_) {}

    triggerWebChimeAndNotification('BROADCAST FROM ${author.toUpperCase()}', message);
  }
}
