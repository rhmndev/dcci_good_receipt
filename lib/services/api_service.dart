import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/api_response.dart';
import '../models/user_model.dart';

class ApiService {
  late Dio _dio;
  String _baseUrl =
      'http://10.100.10.136:8000/api'; // Laravel backend untuk admin DCCI - IP lokal komputer (alternative)
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  ApiService() {
    _dio = Dio();
    _setupInterceptors();
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          print('🌐 API Request: ${options.method} ${options.uri}');
          print('📤 Request Body: ${options.data}');

          // Add token to headers if available
          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Content-Type'] = 'application/json';
          options.headers['Accept'] = 'application/json';
          print('📋 Request Headers: ${options.headers}');
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('✅ API Response: ${response.statusCode}');
          print('📥 Response Body: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          print('❌ API Error: ${error.message}');
          print('❌ Error Response: ${error.response?.data}');
          print('❌ Error Status: ${error.response?.statusCode}');

          // Handle token expiration
          if (error.response?.statusCode == 401) {
            _clearAuthData();
          }
          handler.next(error);
        },
      ),
    );
  }

  Future<void> _clearAuthData() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_data');
  }

  Future<ApiResponse<User>> login(LoginRequest loginRequest) async {
    try {
      print('🔐 Attempting login with username: ${loginRequest.username}');

      final response = await _dio.post(
        '$_baseUrl/login',
        data: loginRequest.toJson(),
      );

      print('✅ Login response received');
      final apiResponse = ApiResponse<User>.fromJson(
        response.data,
        (data) => User.fromJson(data),
      );

      return apiResponse;
    } on DioException catch (e) {
      print('❌ Login failed with DioException: ${e.message}');
      return _handleError<User>(e);
    } catch (e) {
      print('❌ Login failed with unexpected error: $e');
      return ApiResponse<User>(type: 'error', message: 'Unexpected error: $e');
    }
  }

  Future<ApiResponse<User>> checkToken() async {
    try {
      final response = await _dio.get('$_baseUrl/check-token');

      return ApiResponse<User>.fromJson(
        response.data,
        (data) => User.fromJson(data['user']),
      );
    } on DioException catch (e) {
      return _handleError<User>(e);
    }
  }

  Future<ApiResponse<dynamic>> forgotPassword(String email) async {
    try {
      final response = await _dio.post(
        '$_baseUrl/forgot-password',
        data: {'email': email},
      );

      return ApiResponse<dynamic>.fromJson(response.data, null);
    } on DioException catch (e) {
      return _handleError<dynamic>(e);
    }
  }

  ApiResponse<T> _handleError<T>(DioException error) {
    String message = 'Terjadi kesalahan sistem';
    Map<String, dynamic>? errors;

    if (error.response != null) {
      final data = error.response!.data;

      if (data is Map<String, dynamic>) {
        message = data['message'] ?? message;
        errors = data['errors'];
      }

      // Handle specific status codes
      switch (error.response!.statusCode) {
        case 422:
          message = 'Data yang dimasukkan tidak valid';
          break;
        case 423:
          message = 'Akun Anda terkunci. Hubungi administrator.';
          break;
        case 401:
          message = 'Username atau password salah';
          break;
        case 500:
          message = 'Terjadi kesalahan pada server';
          break;
      }
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      message = 'Koneksi timeout. Periksa koneksi internet Anda.';
    } else if (error.type == DioExceptionType.connectionError) {
      message =
          'Tidak dapat terhubung ke server. Periksa koneksi internet Anda.';
    }

    return ApiResponse<T>(type: 'error', message: message, errors: errors);
  }

  void updateBaseUrl(String newBaseUrl) {
    _baseUrl = newBaseUrl;
  }

  String get baseUrl => _baseUrl;
}
