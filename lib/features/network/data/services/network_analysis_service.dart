import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/network_analysis.dart';
import '../models/wifi_network.dart';
import 'dart:developer' as developer;

class NetworkAnalysisService {
  final String baseUrl;

  NetworkAnalysisService() : baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://192.168.0.18:8000/api';

  Future<NetworkAnalysis> analyzeNetwork({
    required String ssid,
    required String bssid,
    required int signalStrength,
    required String securityType,
  }) async {
    try {
      // Format the request body exactly as the API expects
      final requestBody = jsonEncode([
        {
          'ssid': ssid,
          'bssid': bssid,
          'signal_strength': signalStrength,
          'encryption_type': securityType,
          'channel': 6, // Using a default channel as it's required by the API
        }
      ]);

      developer.log('Sending network analysis request: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/networks/analyze'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      );

      developer.log('Network analysis response status: ${response.statusCode}');
      developer.log('Network analysis response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          return NetworkAnalysis.fromJson(data.first);
        }
        throw Exception('No analysis data received');
      } else {
        throw Exception('Failed to analyze network: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Error analyzing network: $e', error: e);
      throw Exception('Failed to analyze network: $e');
    }
  }

  Future<NetworkCheck> checkNetwork({
    required String ssid,
    required String bssid,
  }) async {
    try {
      // Format the request body exactly as the API expects
      final requestBody = jsonEncode({
        'ssid': ssid,
        'bssid': bssid,
        'signal_strength': -65, // Using a default value as it's required by the API
        'encryption_type': 'WPA2', // Using a default value as it's required by the API
        'channel': 6, // Using a default value as it's required by the API
      });

      developer.log('Sending network check request: $requestBody');

      final response = await http.post(
        Uri.parse('$baseUrl/networks/check'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: requestBody,
      );

      developer.log('Network check response status: ${response.statusCode}');
      developer.log('Network check response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return NetworkCheck.fromJson(data);
      } else {
        throw Exception('Failed to check network: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      developer.log('Error checking network: $e', error: e);
      throw Exception('Failed to check network: $e');
    }
  }
} 