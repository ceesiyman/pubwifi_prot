import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../../config/env.dart';
import '../models/api_response.dart';
import '../../core/constants/app_constants.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

class ApiService {
  late final Dio _dio;
  final _storage = const FlutterSecureStorage();
  final String _baseUrl = Env.apiUrl;
  String? _authToken;
  
  // Add getter for Dio instance
  Dio get dio => _dio;
  
  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: Duration(milliseconds: int.parse(dotenv.env['API_TIMEOUT'] ?? '30000')),
        receiveTimeout: Duration(milliseconds: int.parse(dotenv.env['API_TIMEOUT'] ?? '30000')),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
    
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.read(key: AppConstants.authTokenKey);
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (DioException e, handler) async {
          if (e.response?.statusCode == 401) {
            // Handle token refresh here if needed
            final refreshToken = await _storage.read(key: AppConstants.refreshTokenKey);
            if (refreshToken != null) {
              try {
                final response = await _dio.post(
                  '/auth/refresh',
                  data: {'refresh_token': refreshToken},
                );
                
                if (response.statusCode == 200) {
                  final newToken = response.data['access_token'];
                  await _storage.write(key: AppConstants.authTokenKey, value: newToken);
                  
                  // Retry the original request
                  e.requestOptions.headers['Authorization'] = 'Bearer $newToken';
                  final retryResponse = await _dio.fetch(e.requestOptions);
                  return handler.resolve(retryResponse);
                }
              } catch (e) {
                // If refresh fails, clear tokens and redirect to login
                await _storage.deleteAll();
                // TODO: Implement navigation to login screen
              }
            }
          }
          return handler.next(e);
        },
      ),
    );
  }
  
  void setAuthToken(String token) {
    _authToken = token;
  }
  
  Map<String, String> get _headers {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }

    return headers;
  }
  
  Future<ApiResponse> _handleResponse(http.Response response) async {
    final body = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return ApiResponse(
        success: true,
        data: body['data'],
        message: body['message'],
      );
    }

    return ApiResponse(
      success: false,
      message: body['message'] ?? 'An error occurred',
      error: body['errors'],
    );
  }
  
  // Auth endpoints
  Future<ApiResponse> getUser() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/auth/user'),
        headers: _headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }
  
  Future<ApiResponse> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: _headers,
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );

      final result = await _handleResponse(response);
      if (result.success && result.data != null) {
        setAuthToken(result.data['token']);
      }
      return result;
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }
  
  Future<ApiResponse> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: _headers,
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );

      final result = await _handleResponse(response);
      if (result.success && result.data != null) {
        setAuthToken(result.data['token']);
      }
      return result;
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }
  
  Future<ApiResponse> logout() async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/logout'),
        headers: _headers,
      );

      _authToken = null;
      await _storage.deleteAll();
      return await _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }
  
  // Network endpoints
  Future<ApiResponse> scanNetworks() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/networks/scan'),
        headers: _headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }
  
  Future<ApiResponse> checkNetwork(String ssid, String bssid) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/networks/check'),
        headers: _headers,
        body: json.encode({
          'ssid': ssid,
          'bssid': bssid,
        }),
      );
      return await _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }
  
  Future<ApiResponse> reportNetwork(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/networks/report'),
        headers: _headers,
        body: json.encode(data),
      );
      return await _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }
  
  // DNS endpoints
  Future<ApiResponse> getDnsStatus() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/dns/status'),
        headers: _headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }
  
  Future<ApiResponse> updateDnsSettings(Map<String, dynamic> settings) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/dns/settings'),
        headers: _headers,
        body: json.encode(settings),
      );
      return await _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }
  
  // Session endpoints
  Future<ApiResponse> getSessions() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/sessions'),
        headers: _headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }
  
  Future<ApiResponse> endSession(String sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/sessions/$sessionId/end'),
        headers: _headers,
      );
      return await _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: e.toString(),
      );
    }
  }
  
  // Device endpoints
  Future<ApiResponse> getDevices() async {
    try {
      final response = await _dio.get('/devices');
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return ApiResponse.error(e.response?.data['message'] ?? AppConstants.genericError);
    }
  }
  
  Future<ApiResponse> registerDevice(Map<String, dynamic> deviceData) async {
    try {
      final response = await _dio.post('/devices', data: deviceData);
      return ApiResponse.success(response.data);
    } on DioException catch (e) {
      return ApiResponse.error(e.response?.data['message'] ?? AppConstants.genericError);
    }
  }
} 