import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
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

  Future<Map<String, dynamic>> createInviteCode() async {
    final resp = await _dio.dio.post('/invite-codes', data: {});
    return {
      'code': resp.data['code'] as String,
      'shareUrl': resp.data['shareUrl'] as String,
    };
  }

  Future<List<Map<String, dynamic>>> getMyInviteCodes() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) return [];
    final key = 'my_invite_codes_$userId';
    final raw = prefs.getString(key);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(jsonDecode(raw) as List);
  }

  Future<void> saveInviteCode(Map<String, dynamic> code) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId == null) return;
    final key = 'my_invite_codes_$userId';
    final existing = await getMyInviteCodes();
    existing.insert(0, code);
    await prefs.setString(key, jsonEncode(existing));
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
