import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';

import 'api_routes.dart';
import 'dio_Interceptor.dart';

class DioClient {
  final Dio _dio;
  final GetStorage _storage = GetStorage();

  DioClient(this._dio) {
    String baseUrl = ApiRoutes.BASE_URL;
    _dio
      ..options.baseUrl = baseUrl
      ..options.connectTimeout = const Duration(seconds: 40)
      ..options.receiveTimeout = const Duration(seconds: 40)
      ..options.responseType = ResponseType.json
      ..options.contentType = 'application/json'
      ..interceptors.add(DioInterceptor())
      ..interceptors.add(InterceptorsWrapper(
        onRequest: (options, handler) {
          // Add stored cookies to requests
          final cookies = getCookies();
          if (cookies.isNotEmpty) {
            options.headers['Cookie'] = cookies;
          }

          // Add CSRF token if available
          final csrfToken = getCSRFToken();
          if (csrfToken.isNotEmpty) {
            options.headers['X-CSRFToken'] = csrfToken;
          }

          handler.next(options);
        },
        onResponse: (response, handler) {
          // Extract and store cookies from response
          final setCookieHeaders = response.headers['set-cookie'];
          if (setCookieHeaders != null && setCookieHeaders.isNotEmpty) {
            storeCookies(setCookieHeaders);
          }
          handler.next(response);
        },
      ));
  }

  void updateBaseUrl(String baseUrl) {
    _dio.options.baseUrl = baseUrl;
  }

  // Cookie management methods
  String getCookies() {
    final jwtToken = _storage.read('jwt_cookie') ?? '';
    final sessionCookie = _storage.read('openimis_session') ?? '';

    List<String> cookies = [];
    if (jwtToken.isNotEmpty) cookies.add('JWT=$jwtToken');
    if (sessionCookie.isNotEmpty)
      cookies.add('openimis_session=$sessionCookie');

    return cookies.join('; ');
  }

  String getCSRFToken() {
    return _storage.read('csrf_token') ?? '';
  }

  void storeCookies(List<String> setCookieHeaders) {
    for (String cookieHeader in setCookieHeaders) {
      if (cookieHeader.startsWith('JWT=')) {
        final jwtValue =
            cookieHeader.split(';')[0].substring(4); // Remove "JWT="
        _storage.write('jwt_cookie', jwtValue);
      } else if (cookieHeader.startsWith('openimis_session=')) {
        final sessionValue = cookieHeader
            .split(';')[0]
            .substring(17); // Remove "openimis_session="
        _storage.write('openimis_session', sessionValue);
      }
    }
  }

  void storeCSRFToken(String token) {
    _storage.write('csrf_token', token);
  }

  void clearAuthData() {
    _storage.remove('jwt_cookie');
    _storage.remove('openimis_session');
    _storage.remove('csrf_token');
  }

  Future<Response> get(
    String url, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final Response response = await _dio.get(
        url,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> post(
    String url, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final Response response = await _dio.post(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<Response> put(
    String url, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final Response response = await _dio.put(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      rethrow;
    }
  }

  Future<dynamic> delete(
    String url, {
    data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final Response response = await _dio.delete(
        url,
        data: data,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );
      return response.data;
    } catch (e) {
      rethrow;
    }
  }
}
