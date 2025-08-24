import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';
import 'package:hrms_app/core/providers/session_provider.dart';

// Dio Provider with interceptors
final dioProvider = Provider((ref) {
  print('🔍 [ApiService] Creating Dio instance');
  final baseUrl = ApiConfig.getBaseUrl();
  print('🔍 [ApiService] Got baseUrl from ApiConfig: $baseUrl');

  final dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'App-Version': '1.0.0',
        'User-Agent': 'Flutter/HRMS-App/Android',
        'X-App-Type': 'mobile',
        'X-Platform': 'android',
      },
    ),
  );

  // Request interceptor for authentication
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        print('🌐 API Request: ${options.method} ${options.path}');

        // Add authentication token
        final token = await AuthService.getToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          print('🔑 Token added to request');
        }

        return handler.next(options);
      },

      onResponse: (response, handler) {
        print(
          '✅ API Response: ${response.statusCode} ${response.requestOptions.path}',
        );
        return handler.next(response);
      },

      onError: (error, handler) async {
        print(
          '❌ API Error: ${error.response?.statusCode} ${error.requestOptions.path}',
        );
        print('❌ Error Message: ${error.message}');

        // Handle 401 Unauthorized - but exclude login-related and non-critical endpoints
        if (error.response?.statusCode == 401) {
          final path = error.requestOptions.path.toLowerCase();

          // Do NOT auto-logout for these paths
          final shouldBypassAutoLogout =
              // Auth/public flows
              path.contains('login') ||
              path.contains('signup') ||
              path.contains('password') ||
              path.contains('otp') ||
              path.contains('verify') ||
              path.contains('ads') ||
              // Invoice-related endpoints (avoid logging out on permission issues)
              path.contains('/invoices') ||
              path.contains('/tenant/invoices') ||
              path.contains('/owner/invoices');

          if (shouldBypassAutoLogout) {
            print('🔐 401 received on non-critical path, bypassing auto-logout: $path');
            return handler.next(error);
          }

          print('🔐 Token expired or session killed, logging out user');

          // Check if this is a session kill response
          final responseData = error.response?.data;
          if (responseData != null && responseData is Map<String, dynamic>) {
            final message =
                responseData['message']?.toString().toLowerCase() ?? '';
            if (message.contains('session') ||
                message.contains('kill') ||
                message.contains('unauthorized')) {
              print('🚫 Session killed by admin, using session kill handler');
              await AuthService.handleSessionKill();

              // Trigger session kill event (this will be handled by the app)
              // The app will detect the session kill and redirect to login
            } else {
              print('🔐 Regular token expired, using normal logout');
              await AuthService.logout();
            }
          } else {
            // Default to normal logout for 401 errors
            await AuthService.logout();
          }
        }

        return handler.next(error);
      },
    ),
  );

  print(
    '🔍 [ApiService] Dio instance created with baseUrl: ${dio.options.baseUrl}',
  );
  return dio;
});

// API Service class
class ApiService {
  final Dio _dio;

  ApiService(this._dio);

  // GET request
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  // Convenience: system status
  Future<Response> getSystemStatus() {
    return get('/system/status');
  }

  // Kill current session (logout from all devices)
  Future<Response> killSession() async {
    try {
      final response = await _dio.post('/kill-session');
      return response;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  // POST request
  Future<Response> post(String path, {dynamic data}) async {
    try {
      final response = await _dio.post(path, data: data);
      return response;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  // PUT request
  Future<Response> put(String path, {dynamic data}) async {
    try {
      final response = await _dio.put(path, data: data);
      return response;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  // DELETE request
  Future<Response> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      return response;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  // PATCH request
  Future<Response> patch(String path, {dynamic data}) async {
    try {
      final response = await _dio.patch(path, data: data);
      return response;
    } on DioException catch (e) {
      _handleDioError(e);
      rethrow;
    }
  }

  // Handle Dio errors
  void _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        throw Exception('Connection timeout');
      case DioExceptionType.sendTimeout:
        throw Exception('Send timeout');
      case DioExceptionType.receiveTimeout:
        throw Exception('Receive timeout');
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        String message = 'Server error';

        // Parse error message from response
        if (responseData is Map<String, dynamic>) {
          // Handle validation errors (422)
          if (statusCode == 422 && responseData['errors'] != null) {
            final errors = responseData['errors'] as Map<String, dynamic>;
            if (errors.isNotEmpty) {
              final firstError = errors.values.first;
              if (firstError is List && firstError.isNotEmpty) {
                message = firstError[0];
              } else if (firstError is String) {
                message = firstError;
              }
            }
          } else {
            message =
                responseData['error'] ??
                responseData['message'] ??
                responseData['detail'] ??
                'Server error';
          }
        } else if (responseData is String) {
          message = responseData;
        }

        throw Exception('HTTP $statusCode: $message');
      case DioExceptionType.cancel:
        throw Exception('Request cancelled');
      case DioExceptionType.connectionError:
        throw Exception('No internet connection');
      case DioExceptionType.unknown:
        throw Exception('Unknown error occurred');
      default:
        throw Exception('Network error');
    }
  }
}

// API Service Provider
final apiServiceProvider = Provider<ApiService>((ref) {
  final dio = ref.watch(dioProvider);
  return ApiService(dio);
});
