import 'dart:js_interop';

@JS('playEmergencyChime')
external void _playChime();

@JS('showNativeNotification')
external void _showNotification(JSString title, JSString body);

void triggerWebChimeAndNotification(String title, String body) {
  try {
    _playChime();
    _showNotification(title.toJS, body.toJS);
  } catch (_) {}
}
