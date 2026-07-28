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
    try {
      final resp = await _dio.dio.get('/auth/sessions/count');
      return resp.data['count'] as int;
    } catch (_) {
      final sessions = await getSessions();
      return sessions.length;
    }
  }

  Future<List<Map<String, dynamic>>> getSessions() async {
    final resp = await _dio.dio.get('/auth/sessions');
    return List<Map<String, dynamic>>.from(resp.data['sessions'] as List);
  }

  Future<void> revokeSession(String sessionId) async {
    await _dio.dio.post('/auth/sessions/revoke', data: {'sessionId': sessionId});
  }

  Future<Map<String, dynamic>> createInviteCode() async {
    final resp = await _dio.dio.post('/invite-codes', data: {});
    final codeObj = resp.data['code'] as Map<String, dynamic>;
    return {
      'code': codeObj['code'] as String,
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

  Future<void> sendForgotPasswordOtp({
    required String email,
  }) async {
    await _dio.dio.post('/auth/forgot-password', data: {
      'email': email,
    });
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    await _dio.dio.post('/auth/reset-password', data: {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });
  }

  Future<Map<String, dynamic>> setup2Fa() async {
    final resp = await _dio.dio.post('/auth/2fa/setup');
    return {
      'secret': resp.data['secret'] as String,
      'uri': resp.data['uri'] as String,
    };
  }

  Future<void> verify2FaSetup(String code) async {
    await _dio.dio.post('/auth/2fa/verify', data: {'code': code});
  }

  Future<void> disable2Fa() async {
    await _dio.dio.post('/auth/2fa/disable');
  }

  Future<Map<String, dynamic>> verify2FaChallenge({
    required String challengeToken,
    required String code,
  }) async {
    final resp = await _dio.dio.post('/auth/2fa/challenge', data: {
      'challengeToken': challengeToken,
      'code': code,
    });
    return {
      'token': resp.data['token'] as String,
      'refreshToken': resp.data['refreshToken'] as String,
      'user': resp.data['user'] as Map<String, dynamic>,
    };
  }

  Future<void> sendOtp(String phone) async {
    await _dio.dio.post('/auth/otp/send', data: {'phone': phone});
  }

  Future<Map<String, dynamic>> verifyOtp({
    required String phone,
    required String code,
  }) async {
    final resp = await _dio.dio.post('/auth/otp/verify', data: {
      'phone': phone,
      'code': code,
    });
    return {
      'token': resp.data['token'] as String,
      'refreshToken': resp.data['refreshToken'] as String,
      'user': resp.data['user'] as Map<String, dynamic>,
    };
  }

  Future<void> setupPin(String pin) async {
    await _dio.dio.post('/auth/pin/setup', data: {'pin': pin});
  }

  Future<void> removePin() async {
    await _dio.dio.post('/auth/pin/remove');
  }

  Future<bool> getPinStatus() async {
    final resp = await _dio.dio.get('/auth/pin/status');
    return resp.data['enabled'] as bool;
  }

  Future<Map<String, dynamic>> loginWithPin({
    required String email,
    required String pin,
  }) async {
    final resp = await _dio.dio.post('/auth/pin/login', data: {
      'email': email,
      'pin': pin,
    });
    return {
      'token': resp.data['token'] as String,
      'refreshToken': resp.data['refreshToken'] as String,
      'user': resp.data['user'] as Map<String, dynamic>,
    };
  }
}
