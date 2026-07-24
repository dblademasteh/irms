import 'notification_helper_stub.dart'
    if (dart.library.html) 'notification_helper_web.dart' as impl;

class AppNotificationService {
  static void requestPermission() {
    impl.requestNotificationPermission();
  }

  static void show(String title, String body) {
    impl.showSystemNotification(title, body);
  }
}
