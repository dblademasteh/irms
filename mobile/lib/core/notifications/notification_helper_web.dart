// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

void requestNotificationPermission() {
  try {
    if (html.Notification.permission != 'granted' && html.Notification.permission != 'denied') {
      html.Notification.requestPermission();
    }
  } catch (e) {
    print('[WebNotification] Permission error: $e');
  }
}

void showSystemNotification(String title, String body) {
  try {
    if (html.Notification.permission == 'granted') {
      html.Notification(title, body: body, icon: '/favicon.png');
    }
  } catch (e) {
    print('[WebNotification] Show notification error: $e');
  }
}
