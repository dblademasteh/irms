import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'storage.dart';

class DioClient {
  final SecureStorage _storage;
  late final Dio dio;

  DioClient(this._storage, {String baseUrl = 'http://localhost:4000'}) {
    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
    ));

    dio.interceptors.add(_AuthInterceptor(_storage));
  }

  void updateBaseUrl(String url) {
    dio.options.baseUrl = url;
  }

  static String resolveMediaUrl(String baseUrl, String rawUrl) {
    if (rawUrl.isEmpty) return '';
    if (rawUrl.startsWith('http://') || rawUrl.startsWith('https://') || rawUrl.startsWith('data:')) {
      return rawUrl;
    }
    if (rawUrl.startsWith('s3://')) {
      final parts = rawUrl.replaceFirst('s3://', '').split('/');
      if (parts.length >= 2) {
        parts.removeAt(0);
        final key = parts.join('/');
        return resolveMediaUrl(baseUrl, '/public/uploads/$key');
      }
    }
    final cleanBase = baseUrl.endsWith('/') ? baseUrl.substring(0, baseUrl.length - 1) : baseUrl;
    final cleanPath = rawUrl.startsWith('/') ? rawUrl : '/$rawUrl';
    return '$cleanBase$cleanPath';
  }
}

class _AuthInterceptor extends Interceptor {
  final SecureStorage _storage;
  _AuthInterceptor(this._storage);

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final path = options.path;
    final isPublicAuth = path.contains('/auth/login') ||
        path.contains('/auth/register') ||
        path.contains('/auth/refresh') ||
        path.contains('/auth/reset-password');

    if (!isPublicAuth) {
      final token = await _storage.getAccessToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      final refresh = await _storage.getRefreshToken();
      if (refresh != null) {
        try {
          final resp = await Dio().post(
            '${err.requestOptions.baseUrl}/auth/refresh',
            data: {'refreshToken': refresh},
          );
          final newToken = resp.data['token'] as String;
          await _storage.saveTokens(
            accessToken: newToken,
            refreshToken: refresh,
          );
          err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
          final retry = await Dio().fetch(err.requestOptions);
          return handler.resolve(retry);
        } catch (_) {
          await _storage.clearAll();
        }
      }
    }
    handler.next(err);
  }
}
