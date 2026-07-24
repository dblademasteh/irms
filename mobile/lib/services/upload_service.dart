import 'dart:io';
import 'package:dio/dio.dart';

class UploadService {
  final Dio _dio;
  UploadService(this._dio);

  Future<String> uploadFile(String filePath, String contentType) async {
    final presignResp = await _dio.post('/media/presign', data: {
      'type': contentType.contains('video')
          ? 'video'
          : contentType.contains('audio')
              ? 'audio'
              : 'photo',
      'contentType': contentType,
    });
    final uploadUrl = presignResp.data['uploadUrl'] as String;
    final mediaId = presignResp.data['mediaId'] as String;

    final file = File(filePath);
    await _dio.put(
      uploadUrl,
      data: file.openRead(),
      options: Options(
        headers: {'Content-Type': contentType},
      ),
    );

    await _dio.post('/media/confirm', data: {'mediaId': mediaId});
    return mediaId;
  }
}
