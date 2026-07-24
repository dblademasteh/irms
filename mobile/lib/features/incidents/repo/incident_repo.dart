import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../../../core/dio_client.dart';

class IncidentRepo {
  final DioClient _dio;
  IncidentRepo(this._dio);

  Future<Map<String, dynamic>> createIncident({
    required String type,
    required String title,
    String? description,
    String? severity,
    double? latitude,
    double? longitude,
    String? address,
    bool? isAnonymous,
    String? reporterPhone,
    String? barangayId,
    List<String>? mediaIds,
  }) async {
    final Map<String, dynamic> data = {
      'type': type,
      'title': title,
    };
    if (description != null) data['description'] = description;
    if (severity != null) data['severity'] = severity;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (address != null) data['address'] = address;
    if (isAnonymous != null) data['is_anonymous'] = isAnonymous;
    if (reporterPhone != null) data['reporter_phone'] = reporterPhone;
    if (barangayId != null) data['barangay_id'] = barangayId;
    if (mediaIds != null) data['media_ids'] = mediaIds;

    final resp = await _dio.dio.post('/incidents', data: data);
    return resp.data['incident'];
  }

  List<dynamic> _cachedMine = [];

  Future<List<dynamic>> getMine({String? status}) async {
    try {
      final resp = await _dio.dio.get('/incidents/mine',
          queryParameters: status != null ? {'status': status} : null);
      _cachedMine = resp.data['incidents'] as List<dynamic>;
      return _cachedMine;
    } catch (_) {
      // Fallback to offline cached reports
      return _cachedMine;
    }
  }

  Future<Map<String, dynamic>> getById(String id) async {
    final resp = await _dio.dio.get('/incidents/$id');
    return resp.data['incident'];
  }

  Future<Map<String, dynamic>> trackByCode(String code) async {
    final resp = await _dio.dio.get('/incidents/track/$code');
    return resp.data;
  }

  Future<String?> uploadMedia(Uint8List bytes) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: 'photo.jpg', contentType: MediaType('image', 'jpeg')),
      });
      final resp = await _dio.dio.post('/media/upload', data: formData);
      return resp.data['mediaId'] as String?;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> assignDispatcher(String incidentId, String? dispatcherId) async {
    final resp = await _dio.dio.patch('/incidents/$incidentId/assign', data: {
      'dispatcher_id': dispatcherId,
    });
    return resp.data['incident'];
  }

  Future<void> deleteIncident(String id) async {
    await _dio.dio.delete('/incidents/$id');
  }

  Future<List<dynamic>> bulkUpdateStatus(List<String> ids, String status) async {
    final resp = await _dio.dio.post('/incidents/bulk-status', data: {
      'ids': ids,
      'status': status,
    });
    return resp.data['incidents'];
  }
}
