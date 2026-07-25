import 'dart:io';
import 'package:dio/dio.dart';

class UploadService {
  final Dio _dio;
  UploadService(this._dio);

  Future<String> uploadFile(String filePath, String contentType) async {
    final fileName = filePath.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final resp = await _dio.post('/media/upload', data: formData);
    return resp.data['mediaId'] as String;
  }
}
