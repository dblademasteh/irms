import '../../../core/dio_client.dart';

class DispatcherRepo {
  final DioClient _dio;
  DispatcherRepo(this._dio);

  Future<List<dynamic>> getQueue({String? status}) async {
    final resp = await _dio.dio.get('/incidents/queue',
        queryParameters: status != null ? {'status': status} : null);
    return resp.data['incidents'];
  }

  Future<List<dynamic>> searchIncidents({
    String? query,
    String? status,
    String? type,
    String? barangayId,
    String? dateFrom,
    String? dateTo,
  }) async {
    final resp = await _dio.dio.get('/incidents/search', queryParameters: {
      if (query != null && query.isNotEmpty) 'q': query,
      if (status != null) 'status': status,
      if (type != null) 'type': type,
      if (barangayId != null) 'barangay_id': barangayId,
      if (dateFrom != null) 'date_from': dateFrom,
      if (dateTo != null) 'date_to': dateTo,
    });
    return resp.data['incidents'];
  }

  Future<List<dynamic>> getBarangays() async {
    final resp = await _dio.dio.get('/barangays');
    return resp.data['barangays'];
  }

  Future<Map<String, dynamic>> verifyIncident(String id, {String? severity, String? note}) async {
    final resp = await _dio.dio.patch('/incidents/$id/verify', data: {
      if (severity != null) 'severity': severity,
      if (note != null) 'dispatcher_note': note,
    });
    return resp.data['incident'];
  }

  Future<Map<String, dynamic>> rejectIncident(String id, String reason) async {
    final resp = await _dio.dio.patch('/incidents/$id/reject', data: {
      'reason': reason,
    });
    return resp.data['incident'];
  }

  Future<Map<String, dynamic>> declineIncident(String id, String reason) async {
    final resp = await _dio.dio.patch('/incidents/$id/decline', data: {
      'reason': reason,
    });
    return resp.data['incident'];
  }

  Future<Map<String, dynamic>> updateStatus(String id, String status) async {
    final resp = await _dio.dio.patch('/incidents/$id/status', data: {
      'status': status,
    });
    return resp.data['incident'];
  }

  Future<Map<String, dynamic>> resolveIncident(String id, {String? notes}) async {
    final resp = await _dio.dio.patch('/incidents/$id/status', data: {
      'status': 'resolved',
      if (notes != null && notes.isNotEmpty) 'notes': notes,
    });
    return resp.data['incident'];
  }

  Future<Map<String, dynamic>> getIncidentDetails(String id) async {
    final resp = await _dio.dio.get('/incidents/$id');
    return resp.data['incident'];
  }

  Future<List<dynamic>> getIncidentUnits(String incidentId) async {
    final resp = await _dio.dio.get('/incidents/$incidentId/units');
    return resp.data['units'];
  }

  Future<List<dynamic>> getAvailableUnits() async {
    final resp = await _dio.dio.get('/dispatch-units/available');
    return resp.data['units'];
  }

  Future<List<dynamic>> dispatchUnits(String incidentId, List<String> unitIds) async {
    final resp = await _dio.dio.post('/incidents/$incidentId/dispatch', data: {
      'unit_ids': unitIds,
    });
    return resp.data['units'];
  }

  Future<void> removeUnitFromIncident(String incidentId, String unitId) async {
    await _dio.dio.delete('/incidents/$incidentId/units/$unitId');
  }

  Future<void> updateUnitStatus(String incidentId, String unitId, String status) async {
    await _dio.dio.patch('/incidents/$incidentId/units/$unitId/status', data: {
      'status': status,
    });
  }
}