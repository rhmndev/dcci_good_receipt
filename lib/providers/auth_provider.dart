import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/api_response.dart';
import '../services/api_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated, locked }

class AuthProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  static const FlutterSecureStorage _storage = FlutterSecureStorage();

  User? _user;
  String? _token;
  AuthStatus _status = AuthStatus.unknown;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  String? get token => _token;
  AuthStatus get status => _status;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated =>
      _status == AuthStatus.authenticated && _user != null;

  AuthProvider() {
    _checkAuthStatus();
  }

  // Check if user is already authenticated
  Future<void> _checkAuthStatus() async {
    _setLoading(true);

    try {
      _token = await _storage.read(key: 'auth_token');

      if (_token != null) {
        final response = await _apiService.checkToken();

        if (response.isSuccess && response.data != null) {
          _user = response.data;
          _status = AuthStatus.authenticated;
        } else {
          await _clearAuthData();
          _status = AuthStatus.unauthenticated;
        }
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      await _clearAuthData();
      _status = AuthStatus.unauthenticated;
    }

    _setLoading(false);
  }

  // Login function
  Future<bool> login(String username, String password) async {
    _setLoading(true);
    _clearError();

    try {
      final loginRequest = LoginRequest(username: username, password: password);

      final response = await _apiService.login(loginRequest);

      if (response.isSuccess &&
          response.data != null &&
          response.token != null) {
        _user = response.data;
        _token = response.token;
        _status = AuthStatus.authenticated;

        // Save auth data
        await _storage.write(key: 'auth_token', value: _token!);
        await _storage.write(
          key: 'user_data',
          value: jsonEncode(_user!.toJson()),
        );

        // Save permissions if available
        if (response.permissions != null) {
          await _storage.write(
            key: 'user_permissions',
            value: jsonEncode(response.permissions),
          );
        }

        _setLoading(false);
        return true;
      } else {
        _errorMessage = response.message;

        // Check if account is locked
        if (response.errors != null && response.errors!.containsKey('locked')) {
          _status = AuthStatus.locked;
        } else {
          _status = AuthStatus.unauthenticated;
        }

        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan saat login: ${e.toString()}';
      _status = AuthStatus.unauthenticated;
      _setLoading(false);
      return false;
    }
  }

  // Logout function
  Future<void> logout() async {
    _setLoading(true);

    await _clearAuthData();

    _user = null;
    _token = null;
    _status = AuthStatus.unauthenticated;

    _setLoading(false);
  }

  // Forgot password
  Future<bool> forgotPassword(String email) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _apiService.forgotPassword(email);

      if (response.isSuccess) {
        _setLoading(false);
        return true;
      } else {
        _errorMessage = response.message;
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: ${e.toString()}';
      _setLoading(false);
      return false;
    }
  }

  // Clear authentication data
  Future<void> _clearAuthData() async {
    await _storage.delete(key: 'auth_token');
    await _storage.delete(key: 'user_data');
    await _storage.delete(key: 'user_permissions');
  }

  // Helper methods
  void _setLoading(bool loading) {
    if (_isLoading != loading) {
      _isLoading = loading;
      notifyListeners();
    }
  }

  void _clearError() {
    if (_errorMessage != null) {
      _errorMessage = null;
      notifyListeners();
    }
  }

  // Get user permissions
  Future<List<dynamic>?> getUserPermissions() async {
    final permissionsStr = await _storage.read(key: 'user_permissions');
    if (permissionsStr != null) {
      return jsonDecode(permissionsStr);
    }
    return null;
  }

  // Check if user has specific permission
  Future<bool> hasPermission(String permissionName) async {
    final permissions = await getUserPermissions();
    if (permissions == null) return false;

    // Check if permission exists in the list
    for (var permission in permissions) {
      if (permission['name'] == permissionName) {
        return true;
      }
      // Check children permissions
      if (permission['children'] != null) {
        for (var child in permission['children']) {
          if (child['name'] == permissionName) {
            return true;
          }
        }
      }
    }

    return false;
  }

  // Update user profile
  void updateUser(User updatedUser) {
    _user = updatedUser;
    _storage.write(key: 'user_data', value: jsonEncode(_user!.toJson()));
    notifyListeners();
  }
}
