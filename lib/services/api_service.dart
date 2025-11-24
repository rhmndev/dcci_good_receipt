import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/api_response.dart';
import '../models/user_model.dart';
import '../models/good_receipt_model.dart';

class ApiService {
  late Dio _dio;
  String _baseUrl = '';
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  // List of possible endpoints to try
  static const List<String> _possibleEndpoints = [
    'http://10.0.2.2:8000/api', // Android emulator
    'http://localhost:8000/api', // Local development
    'http://127.0.0.1:8000/api', // Local loopback/localhost
    'http://10.100.10.57:8000/api', // sesuaikan sama IP Komputer, lalu buka browser HP ketikan (https://IP_KOMPUTER:8000) untuk connect ke local server backend laravel (dci-ais-be)
    'http://192.168.1.100:8000/api', // Common local network
  ];

  ApiService() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 60),
    ));
    _initializeBaseUrl();
    _setupInterceptors();
  }

  Future<void> _initializeBaseUrl() async {
    // Try to get previously working URL from storage
    final savedUrl = await _storage.read(key: 'working_base_url');
    if (savedUrl != null && savedUrl.isNotEmpty) {
      _baseUrl = savedUrl;
      print('🔧 Using saved working URL: $_baseUrl');
      return;
    }

    // Auto-detect working endpoint
    for (String endpoint in _possibleEndpoints) {
      try {
        print('🔍 Testing endpoint: $endpoint');
        final dio = Dio(BaseOptions(
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ));
        
        final response = await dio.get('$endpoint/health-check');
        if (response.statusCode == 200) {
          _baseUrl = endpoint;
          await _storage.write(key: 'working_base_url', value: endpoint);
          print('✅ Found working endpoint: $_baseUrl');
          break;
        }
      } catch (e) {
        print('❌ Endpoint $endpoint failed: $e');
        continue;
      }
    }

    // Fallback to first endpoint if none work
    if (_baseUrl.isEmpty) {
      _baseUrl = _possibleEndpoints.first;
      print('⚠️ Using fallback endpoint: $_baseUrl');
    }
  }

  void _setupInterceptors() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_baseUrl.isNotEmpty) {
            options.baseUrl = _baseUrl;
          }

          final token = await _storage.read(key: 'auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers['Accept'] = 'application/json';
          
          print('🌐 API Request: ${options.method} ${options.path}');
          print('📤 Request Body: ${options.data}');
          print('📋 Request Headers: ${options.headers}');
          
          handler.next(options);
        },
        onResponse: (response, handler) {
          print('📥 Response Status: ${response.statusCode}');
          print('📥 Response Data: ${response.data}');
          handler.next(response);
        },
        onError: (error, handler) {
          print('❌ API Error: ${error.message}');
          print('❌ Error Response: ${error.response?.data}');
          print('❌ Error Status: ${error.response?.statusCode}');
          handler.next(error);
        },
      ),
    );
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

  // Scan QR Code dari Portal Supplier Database
  Future<ApiResponse<ScannedOutgoingRequest>> scanOutgoingQR(String qrCode) async {
    try {
      print('📱 Scanning QR Code: $qrCode');
      print('🌐 Portal Supplier API Endpoint: $_baseUrl/scan-outgoing-qr');

      final response = await _dio.post(
        '/scan-outgoing-qr',
        data: {'qr_code': qrCode},
      );

      print('✅ QR Scan response: ${response.statusCode}');
      print('📄 Portal Supplier response data: ${response.data}');
      
      final apiResponse = ApiResponse<ScannedOutgoingRequest>.fromJson(
        response.data,
        (data) => ScannedOutgoingRequest.fromJson(data),
      );

      return apiResponse;
    } on DioException catch (e) {
      print('❌ Portal Supplier QR Scan DioException: ${e.message}');
      print('❌ Error type: ${e.type}');
      print('❌ Error response: ${e.response?.data}');
      print('❌ Error status code: ${e.response?.statusCode}');
      
      return _handleError<ScannedOutgoingRequest>(e);
    } catch (e) {
      print('❌ Portal Supplier QR Scan unexpected error: $e');
      print('❌ Error runtimeType: ${e.runtimeType}');
      
      return ApiResponse<ScannedOutgoingRequest>(
        type: 'error',
        message: 'QR Code tidak ditemukan di Portal Supplier atau terjadi kesalahan koneksi'
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

  // Get list Good Receipts
  Future<ApiResponse<List<GoodReceipt>>> getGoodReceipts() async {
    try {
      print('📋 Getting Good Receipts list...');

      final response = await _dio.get('/good-receipts');

      print('✅ Good Receipts retrieved successfully');
      final apiResponse = ApiResponse<List<GoodReceipt>>.fromJson(
        response.data,
        (data) => (data as List).map((item) => GoodReceipt.fromJson(item)).toList(),
      );

      return apiResponse;
    } on DioException catch (e) {
      print('❌ Get Good Receipts failed: ${e.message}');
      return _handleError<List<GoodReceipt>>(e);
    } catch (e) {
      print('❌ Get Good Receipts unexpected error: $e');
      return ApiResponse<List<GoodReceipt>>(
        type: 'error',
        message: 'Unexpected error: $e'
      );
    }
  }

  // Archive Outgoing Request setelah Good Receipt dibuat
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