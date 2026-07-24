import 'package:dio/dio.dart';

class PushService {
  final Dio _dio;
  PushService(this._dio);

  /// Register device token with backend.
  /// Call after FCM/APNs token is obtained.
  Future<void> registerToken(String token, String platform) async {
    await _dio.post('/auth/device', data: {
      if (platform == 'android') 'fcmToken': token,
      if (platform == 'ios') 'apnsToken': token,
    });
  }
}
