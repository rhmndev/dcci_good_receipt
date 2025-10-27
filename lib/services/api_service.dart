import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/api_response.dart';
import '../models/user_model.dart';
import '../models/good_receipt_model.dart';

class ApiService {
  late Dio _dio;
  String _baseUrl =
      'http://10.23.184.86:8000/api'; // Laravel backend untuk admin DCCI pakai IP Local Komputer
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

  // Scan QR Code untuk mendapatkan data Outgoing Request
  Future<ApiResponse<ScannedOutgoingRequest>> scanOutgoingQR(String qrCode) async {
    try {
      print('📱 Scanning QR Code: $qrCode');

      final response = await _dio.post(
        '/scan-outgoing-qr',
        data: {'qr_code': qrCode},
      );

      print('✅ QR Scan successful');
      final apiResponse = ApiResponse<ScannedOutgoingRequest>.fromJson(
        response.data,
        (data) => ScannedOutgoingRequest.fromJson(data),
      );

      return apiResponse;
    } on DioException catch (e) {
      print('❌ QR Scan failed: ${e.message}');
      return _handleError<ScannedOutgoingRequest>(e);
    } catch (e) {
      print('❌ QR Scan unexpected error: $e');
      return ApiResponse<ScannedOutgoingRequest>(
        type: 'error',
        message: 'Unexpected error: $e'
      );
    }
  }

  // Create Good Receipt dari hasil scan
  Future<ApiResponse<GoodReceipt>> createGoodReceipt(Map<String, dynamic> receiptData) async {
    try {
      print('📝 Creating Good Receipt...');

      final response = await _dio.post(
        '/good-receipts',
        data: receiptData,
      );

      print('✅ Good Receipt created successfully');
      final apiResponse = ApiResponse<GoodReceipt>.fromJson(
        response.data,
        (data) => GoodReceipt.fromJson(data),
      );

      return apiResponse;
    } on DioException catch (e) {
      print('❌ Create Good Receipt failed: ${e.message}');
      return _handleError<GoodReceipt>(e);
    } catch (e) {
      print('❌ Create Good Receipt unexpected error: $e');
      return ApiResponse<GoodReceipt>(
        type: 'error',
        message: 'Unexpected error: $e'
      );
    }
  }

  // Get all Good Receipts
  Future<ApiResponse<List<GoodReceipt>>> getGoodReceipts() async {
    try {
      print('📋 Fetching Good Receipts...');

      final response = await _dio.get('/good-receipts');

      print('✅ Good Receipts fetched successfully');
      final List<dynamic> receiptsJson = response.data['data'] ?? response.data;
      final receipts = receiptsJson
          .map((receipt) => GoodReceipt.fromJson(receipt))
          .toList();

      return ApiResponse<List<GoodReceipt>>(
        type: 'success',
        message: 'Good Receipts fetched successfully',
        data: receipts,
      );
    } on DioException catch (e) {
      print('❌ Fetch Good Receipts failed: ${e.message}');
      return _handleError<List<GoodReceipt>>(e);
    } catch (e) {
      print('❌ Fetch Good Receipts unexpected error: $e');
      return ApiResponse<List<GoodReceipt>>(
        type: 'error',
        message: 'Unexpected error: $e'
      );
    }
  }

  // Archive Outgoing Request (panggil setelah Good Receipt dibuat)
  Future<ApiResponse<dynamic>> archiveOutgoingRequest(String outgoingNumber) async {
    try {
      print('📦 Archiving Outgoing Request: $outgoingNumber');

      final response = await _dio.post(
        '/outgoing-request/archived',
        data: {
          'outgoing_number': outgoingNumber,
          'archived_by': 'DCCI Admin Mobile',
          'archived_at': DateTime.now().toIso8601String(),
        },
      );

      print('✅ Outgoing Request archived successfully');
      return ApiResponse<dynamic>.fromJson(response.data, null);
    } on DioException catch (e) {
      print('❌ Archive Outgoing Request failed: ${e.message}');
      return _handleError<dynamic>(e);
    } catch (e) {
      print('❌ Archive Outgoing Request unexpected error: $e');
      return ApiResponse<dynamic>(
        type: 'error',
        message: 'Unexpected error: $e'
      );
    }
  }

  // Post Good Receipt ke SAP
  Future<ApiResponse<dynamic>> postGoodReceiptToSAP(String receiptId) async {
    try {
      print('🔄 Posting Good Receipt to SAP: $receiptId');

      final response = await _dio.post(
        '/good-receipts/$receiptId/post-to-sap',
      );

      print('✅ Good Receipt posted to SAP successfully');
      return ApiResponse<dynamic>.fromJson(response.data, null);
    } on DioException catch (e) {
      print('❌ Post to SAP failed: ${e.message}');
      return _handleError<dynamic>(e);
    } catch (e) {
      print('❌ Post to SAP unexpected error: $e');
      return ApiResponse<dynamic>(
        type: 'error',
        message: 'Unexpected error: $e'
      );
    }
  }
}
