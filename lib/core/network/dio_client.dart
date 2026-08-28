import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

class DioClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: dotenv.env['API_URL'] ?? 'https://mulberry-antiques-hunter.ngrok-free.dev/api',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'ngrok-skip-browser-warning': 'true',
      },
    ),
  )..interceptors.add(PrettyDioLogger(
      requestHeader: true,
      requestBody: true,
      responseBody: true,
      compact: true,
    ));

  static Dio get instance => _dio;

  static void setAuthToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  static void clearAuth() {
    _dio.options.headers.remove('Authorization');
  }

  static void setupInterceptors() {
    _dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        if (error.response?.statusCode == 401) {
          await _handleTokenRefresh();
        }
        return handler.next(error);
      },
    ));
  }

  static Future<void> _handleTokenRefresh() async {
    // Refresh token logic handler
  }
}
