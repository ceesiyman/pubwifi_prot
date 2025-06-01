import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pubwifi_prot/core/config/api_config.dart';
import 'package:pubwifi_prot/shared/services/api_service.dart';

class VpnApiResponse {
  final String status;
  final String? message;
  final Map<String, dynamic> data;

  VpnApiResponse({
    required this.status,
    this.message,
    required this.data,
  });

  factory VpnApiResponse.fromJson(Map<String, dynamic> json) {
    return VpnApiResponse(
      status: json['status'] as String,
      message: json['message'] as String?,
      data: json['data'] as Map<String, dynamic>,
    );
  }
}

class VpnApiClient {
  final Dio _dio;

  VpnApiClient(this._dio);

  Future<VpnApiResponse> getStatus() async {
    final response = await _dio.get('/vpn/status');
    return VpnApiResponse.fromJson(response.data);
  }

  Future<VpnApiResponse> connect() async {
    final response = await _dio.post('/vpn/connect');
    return VpnApiResponse.fromJson(response.data);
  }

  Future<VpnApiResponse> disconnect() async {
    final response = await _dio.post('/vpn/disconnect');
    return VpnApiResponse.fromJson(response.data);
  }

  Future<VpnApiResponse> updateStats({
    required int bytesSent,
    required int bytesReceived,
  }) async {
    final response = await _dio.post(
      '/vpn/stats',
      data: {
        'bytes_sent': bytesSent,
        'bytes_received': bytesReceived,
      },
    );
    return VpnApiResponse.fromJson(response.data);
  }
}

final vpnApiClientProvider = Provider<VpnApiClient>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  return VpnApiClient(apiService.dio);
}); 
 
 
 
 
 
 
 