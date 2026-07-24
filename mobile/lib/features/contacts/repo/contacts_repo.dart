import '../../../core/dio_client.dart';

class ContactsRepo {
  final DioClient _api;
  ContactsRepo(this._api);

  List<Map<String, dynamic>> _cachedContacts = [];
  List<Map<String, dynamic>> _cachedCategories = [];

  Future<List<Map<String, dynamic>>> getContacts() async {
    try {
      final resp = await _api.dio.get('/contacts');
      _cachedContacts = List<Map<String, dynamic>>.from(resp.data['contacts']);
      return _cachedContacts;
    } catch (_) {
      return _cachedContacts;
    }
  }

  Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final resp = await _api.dio.get('/contact-categories');
      _cachedCategories = List<Map<String, dynamic>>.from(resp.data['categories']);
      return _cachedCategories;
    } catch (_) {
      return _cachedCategories;
    }
  }
}
