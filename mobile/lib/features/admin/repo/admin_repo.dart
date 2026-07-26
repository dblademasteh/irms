import 'package:dio/dio.dart';
import '../../../core/dio_client.dart';

class AdminRepo {
  final DioClient _api;

  AdminRepo(this._api);

  Future<List<dynamic>> getUsers() async {
    final resp = await _api.dio.get('/admin/users');
    return resp.data['users'];
  }

  Future<Map<String, dynamic>> updateUserRole(String id, String role) async {
    final resp = await _api.dio.put('/admin/users/$id/role', data: {'role': role});
    return resp.data['user'];
  }

  Future<void> resetUserPassword(String userId, String newPassword) async {
    await _api.dio.post('/admin/users/$userId/reset-password', data: {'newPassword': newPassword});
  }

  Future<Map<String, dynamic>> getAnalytics() async {
    final resp = await _api.dio.get('/admin/analytics');
    return resp.data['analytics'];
  }

  Future<void> sendBroadcast(String message, {String? category, String? targetRole}) async {
    await _api.dio.post('/admin/broadcast', data: {
      'message': message,
      if (category != null) 'category': category,
      if (targetRole != null) 'target_role': targetRole,
    });
  }

  Future<List<dynamic>> getBroadcasts() async {
    final resp = await _api.dio.get('/admin/broadcasts');
    return resp.data['broadcasts'];
  }

  Future<List<dynamic>> getBroadcastTemplates() async {
    final resp = await _api.dio.get('/admin/broadcast-templates');
    return resp.data['templates'];
  }

  Future<Map<String, String>> generateBroadcast({
    required String template,
    String? details,
    String? barangay,
  }) async {
    final resp = await _api.dio.post('/admin/broadcast/generate', data: {
      'template': template,
      if (details != null && details.isNotEmpty) 'details': details,
      if (barangay != null && barangay.isNotEmpty) 'barangay': barangay,
    });
    return {
      'message': resp.data['message'] as String,
      'category': resp.data['category'] as String,
    };
  }

  Future<List<dynamic>> getContacts() async {
    final resp = await _api.dio.get('/contacts');
    return resp.data['contacts'];
  }

  Future<Map<String, dynamic>> addContact(String name, String phone, String department, String categoryId) async {
    final resp = await _api.dio.post('/contacts', data: {
      'name': name,
      'phone': phone,
      'department': department,
      'category_id': categoryId,
    });
    return resp.data['contact'];
  }

  Future<Map<String, dynamic>> updateContact(String id, String name, String phone, String department, String categoryId) async {
    final resp = await _api.dio.put('/contacts/$id', data: {
      'name': name,
      'phone': phone,
      'department': department,
      'category_id': categoryId,
    });
    return resp.data['contact'];
  }

  Future<void> deleteContact(String id) async {
    await _api.dio.delete('/contacts/$id');
  }

  Future<List<dynamic>> getCategories() async {
    final resp = await _api.dio.get('/contact-categories');
    return resp.data['categories'];
  }

  Future<Map<String, dynamic>> addCategory(String name, String icon, String color, int sortOrder) async {
    final resp = await _api.dio.post('/contact-categories', data: {
      'name': name,
      'icon': icon,
      'color': color,
      'sort_order': sortOrder,
    });
    return resp.data['category'];
  }

  Future<Map<String, dynamic>> updateCategory(String id, String name, String icon, String color, int sortOrder) async {
    final resp = await _api.dio.put('/contact-categories/$id', data: {
      'name': name,
      'icon': icon,
      'color': color,
      'sort_order': sortOrder,
    });
    return resp.data['category'];
  }

  Future<void> deleteCategory(String id) async {
    await _api.dio.delete('/contact-categories/$id');
  }

  Future<Map<String, dynamic>> batchImportContacts(List<Map<String, String>> contacts) async {
    final resp = await _api.dio.post('/contacts/batch', data: {
      'contacts': contacts,
    });
    return resp.data;
  }

  Future<List<dynamic>> getInviteCodes() async {
    final resp = await _api.dio.get('/invite-codes');
    return resp.data['codes'];
  }

  Future<Map<String, dynamic>> createInviteCode(String role, {String? expiresAt}) async {
    final resp = await _api.dio.post('/invite-codes', data: {
      'role': role,
      if (expiresAt != null) 'expires_at': expiresAt,
    });
    return resp.data['code'];
  }

  Future<void> deleteInviteCode(String id) async {
    await _api.dio.delete('/invite-codes/$id');
  }

  Future<List<dynamic>> getBarangays() async {
    final resp = await _api.dio.get('/barangays');
    return resp.data['barangays'];
  }

  Future<Map<String, dynamic>> addBarangay(String name, String? psgcCode, bool isUrban) async {
    final resp = await _api.dio.post('/barangays', data: {
      'name': name,
      if (psgcCode != null && psgcCode.isNotEmpty) 'psgc_code': psgcCode,
      'is_urban': isUrban,
    });
    return resp.data['barangay'];
  }

  Future<Map<String, dynamic>> updateBarangay(String id, String name, String? psgcCode, bool isUrban) async {
    final resp = await _api.dio.put('/barangays/$id', data: {
      'name': name,
      if (psgcCode != null && psgcCode.isNotEmpty) 'psgc_code': psgcCode,
      'is_urban': isUrban,
    });
    return resp.data['barangay'];
  }

  Future<void> deleteBarangay(String id) async {
    await _api.dio.delete('/barangays/$id');
  }

  Future<List<dynamic>> getIncidents() async {
    final resp = await _api.dio.get('/incidents/queue');
    return resp.data['incidents'];
  }

  Future<void> deleteIncident(String id) async {
    await _api.dio.delete('/incidents/$id');
  }

  Future<String> exportIncidents({String? dateFrom, String? dateTo, String? status, String? type}) async {
    final resp = await _api.dio.get('/incidents/export', queryParameters: {
      if (dateFrom != null) 'date_from': dateFrom,
      if (dateTo != null) 'date_to': dateTo,
      if (status != null) 'status': status,
      if (type != null) 'type': type,
    }, options: Options(responseType: ResponseType.plain));
    return resp.data;
  }

  Future<List<dynamic>> getIncidentStatsByBarangay() async {
    final resp = await _api.dio.get('/admin/analytics');
    return resp.data['analytics']['barangayBreakdown'] ?? [];
  }

  Future<List<dynamic>> getUnits() async {
    final resp = await _api.dio.get('/dispatch-units');
    return resp.data['units'] ?? [];
  }

  Future<Map<String, dynamic>> addUnit(String name, String unitType) async {
    final resp = await _api.dio.post('/dispatch-units', data: {
      'name': name,
      'unit_type': unitType,
    });
    return resp.data['unit'];
  }

  Future<Map<String, dynamic>> updateUnitStatus(String id, String status) async {
    final resp = await _api.dio.patch('/dispatch-units/$id/status', data: {
      'status': status,
    });
    return resp.data['unit'];
  }

  Future<void> deleteUnit(String id) async {
    await _api.dio.delete('/dispatch-units/$id');
  }
}
