import '../../../core/dio_client.dart';

class AuthRepo {
  final DioClient _dio;
  AuthRepo(this._dio);

  Future<Map<String, dynamic>> register({
    required String name,
    String? email,
    required String phone,
    String? address,
    required String password,
    String? inviteCode,
  }) async {
    final resp = await _dio.dio.post('/auth/register', data: {
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'password': password,
      'invite_code': inviteCode,
    });
    return resp.data;
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final resp = await _dio.dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    return resp.data;
  }

  Future<Map<String, dynamic>> getCurrentUser() async {
    final resp = await _dio.dio.get('/auth/me');
    return resp.data;
  }

  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? address,
  }) async {
    final data = <String, dynamic>{};
    if (name != null) data['name'] = name;
    if (phone != null) data['phone'] = phone;
    if (address != null) data['address'] = address;
    final resp = await _dio.dio.patch('/auth/profile', data: data);
    return resp.data;
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _dio.dio.post('/auth/change-password', data: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<int> getSessionCount() async {
    final resp = await _dio.dio.get('/auth/sessions/count');
    return resp.data['count'] as int;
  }

  Future<void> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    await _dio.dio.post('/auth/reset-password', data: {
      'email': email,
      'newPassword': newPassword,
    });
  }
}
