import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _token;
  String? _role;
  int? _userId;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String? get token => _token;
  String? get role => _role;
  int? get userId => _userId;
  String get errorMessage => _errorMessage;
  bool get isAuthenticated => _token != null;

  String get apiBaseUrl {
    return api.baseUrl;
  }

  final ApiService api = ApiService();

  void setApiBaseUrl(String baseUrl) {
    api.setBaseUrl(baseUrl);
    debugPrint('AuthProvider baseUrl set to: ${api.baseUrl}');
    notifyListeners();
  }

  AuthProvider() {
    debugPrint('AuthProvider baseUrl: ${api.baseUrl}');
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    final fullUrl = '${api.baseUrl}/login';
    debugPrint('Attempt login to: $fullUrl');

    try {
      final data = await api.login(email, password);
      final token = data['token'] ?? data['access_token'];
      final role = data['role'] ?? (data['user'] as Map?)?['role'];
      final userId = (data['user'] as Map?)?['id'];

      if (token == null || role == null) {
        _errorMessage = 'Respons login tidak sesuai format yang diharapkan.';
      } else {
        _token = token.toString();
        _role = role.toString();
        _userId = int.tryParse(userId.toString());
        api.setToken(_token);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('role', _role!);
        if (_userId != null) await prefs.setInt('user_id', _userId!);

        _isLoading = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Unexpected login error: $e');
      _errorMessage = ApiService.errorMessage(e);
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  Future<void> checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _role = prefs.getString('role');
    _userId = prefs.getInt('user_id');
    api.setToken(_token);
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      if (_token != null) await api.logout();
    } catch (error) {
      debugPrint('Remote logout failed: $error');
    }
    await prefs.remove('token');
    await prefs.remove('role');
    await prefs.remove('user_id');
    _token = null;
    _role = null;
    _userId = null;
    api.setToken(null);

    // Opsional: Lakukan request logout ke backend Laravel di sini jika menggunakan token revocation

    notifyListeners();
  }
}
