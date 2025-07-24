import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hrms_app/core/utils/api_config.dart';
import 'package:hrms_app/features/auth/data/services/auth_service.dart';

// Dio Provider with interceptors
final dioProvider = Provider((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: ApiConfig.getBaseUrl(),
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
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

        // Handle 401 Unauthorized
        if (error.response?.statusCode == 401) {
          print('🔐 Token expired, logging out user');
          await AuthService.logout();
          // TODO: Navigate to login screen
        }

        return handler.next(error);
      },
    ),
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
        final message = error.response?.data?['message'] ?? 'Server error';
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
