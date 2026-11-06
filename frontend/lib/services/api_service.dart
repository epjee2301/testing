import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const _configuredBaseUrl = String.fromEnvironment('API_BASE_URL');

  ApiService()
    : _dio = Dio(
        BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: const {
            'Accept': 'application/json',
            'Content-Type': 'application/json',
          },
        ),
      );

  static String get _baseUrl {
    if (_configuredBaseUrl.isNotEmpty) {
      return _normalizeBaseUrl(_configuredBaseUrl);
    }
    if (kIsWeb) return 'http://127.0.0.1:8000/api';
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000/api';
    }
    return 'http://127.0.0.1:8000/api';
  }

  static String _normalizeBaseUrl(String baseUrl) {
    final normalized = baseUrl.trim().replaceFirst(RegExp(r'/+$'), '');
    if (normalized.isEmpty) {
      throw ArgumentError.value(baseUrl, 'baseUrl', 'Must not be empty.');
    }
    return normalized.endsWith('/api') ? normalized : '$normalized/api';
  }

  final Dio _dio;

  String get baseUrl => _dio.options.baseUrl;

  void setBaseUrl(String baseUrl) {
    _dio.options.baseUrl = _normalizeBaseUrl(baseUrl);
  }

  void setToken(String? token) {
    if (token == null || token.isEmpty) {
      _dio.options.headers.remove('Authorization');
    } else {
      _dio.options.headers['Authorization'] = 'Bearer $token';
    }
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/login',
      data: {'email': email, 'password': password},
    );
    return response.data ?? <String, dynamic>{};
  }

  Future<void> logout() async {
    await _dio.post<void>('/logout');
  }

  Future<Map<String, dynamic>> profile() async {
    final response = await _dio.get<Map<String, dynamic>>('/profile');
    return _mapData(response.data);
  }

  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> data) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/profile',
      data: data,
    );
    return _mapData(response.data);
  }

  Future<List<Map<String, dynamic>>> attendance(String month) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/attendance',
      queryParameters: {'month': month},
    );
    return _mapList(response.data);
  }

  Future<Map<String, dynamic>> hrdDashboard({
    String? month,
    String? date,
  }) async {
    final queryParameters = <String, String>{};
    if (month != null) queryParameters['month'] = month;
    if (date != null) queryParameters['date'] = date;

    final response = await _dio.get<Map<String, dynamic>>(
      '/hrd/dashboard',
      queryParameters: queryParameters,
    );
    return _mapData(response.data);
  }

  Future<Map<String, dynamic>> recordAttendance(String action) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/attendance/$action',
    );
    return _mapData(response.data);
  }

  Future<List<Map<String, dynamic>>> requests() async {
    final response = await _dio.get<Map<String, dynamic>>('/requests');
    return _mapList(response.data);
  }

  Future<Map<String, dynamic>> submitRequest(Map<String, dynamic> data) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/requests',
      data: data,
    );
    return _mapData(response.data);
  }

  Future<Map<String, dynamic>> decideRequest(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/requests/$requestId/decision',
      data: data,
    );
    return _mapData(response.data);
  }

  static Map<String, dynamic> _mapData(Map<String, dynamic>? response) {
    final data = response?['data'];
    return data is Map ? Map<String, dynamic>.from(data) : <String, dynamic>{};
  }

  static List<Map<String, dynamic>> _mapList(Map<String, dynamic>? response) {
    final data = response?['data'];
    if (data is! List) return const [];
    return data.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }

  static String errorMessage(Object error) {
    if (error is DioException) {
      final response = error.response?.data;
      if (response is Map && response['message'] is String) {
        return response['message'] as String;
      }
      if (error.response == null) {
        return 'Tidak dapat terhubung ke server. Pastikan Laravel aktif di port 8000.';
      }
    }
    return 'Terjadi kesalahan. Silakan coba lagi.';
  }
}
