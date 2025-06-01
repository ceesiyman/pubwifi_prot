import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../data/vpn_api_client.dart';
import '../models/vpn_state.dart';
import '../utils/log.dart';

final vpnProvider = StateNotifierProvider<VpnNotifier, VpnState>((ref) {
  return VpnNotifier(ref.watch(vpnApiClientProvider));
});

class VpnNotifier extends StateNotifier<VpnState> {
  final VpnApiClient _apiClient;
  Timer? _statsTimer;
  String? _configPath;

  VpnNotifier(this._apiClient) : super(const VpnState()) {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Request network permissions
      if (Platform.isAndroid) {
        final status = await Permission.location.request();
        if (!status.isGranted) {
          throw Exception('Location permission not granted');
        }
      }
      
      // Check VPN status
      await checkVpnStatus();
    } catch (e) {
      state = state.copyWith(
        status: 'error',
        error: e.toString(),
      );
    }
  }

  Future<void> checkVpnStatus() async {
    try {
      final response = await _apiClient.getStatus();
      if (response.status == 'success') {
        final data = response.data;
        state = state.copyWith(
          status: data['status'],
          bytesSent: data['bytes_sent'] ?? 0,
          bytesReceived: data['bytes_received'] ?? 0,
          clientIp: data['client_ip'],
          serverAddress: data['server_address'],
          serverPort: data['server_port'],
          connectedAt: data['connected_at'] != null
              ? DateTime.parse(data['connected_at'])
              : null,
        );

        // Start stats updates if connected
        if (data['status'] == 'active') {
          _startStatsUpdates();
        } else {
          _stopStatsUpdates();
        }
      }
    } catch (e) {
      state = state.copyWith(
        status: 'error',
        error: e.toString(),
      );
    }
  }

  Future<void> connect() async {
    try {
      state = state.copyWith(status: 'connecting');

      // Get VPN configuration from server
      final response = await _apiClient.connect();
      if (response.status == 'success') {
        final data = response.data;
        
        // Save configuration for future use
        if (data['config'] != null) {
          try {
            final config = utf8.decode(base64.decode(data['config']));
            Log.info('VPN configuration received', {'config_length': config.length});
            
            // Validate the configuration format
            if (!config.contains('[Interface]') || !config.contains('[Peer]')) {
              throw Exception('Invalid VPN configuration format');
            }
            
            _configPath = await _saveConfig(config);
            Log.info('VPN configuration saved', {'path': _configPath});
          } catch (e) {
            Log.error('Failed to decode VPN configuration', {'error': e.toString()});
            throw Exception('Failed to decode VPN configuration: $e');
          }
        } else {
          throw Exception('No VPN configuration received from server');
        }

        state = state.copyWith(
          status: 'active',
          bytesSent: data['bytes_sent'] ?? 0,
          bytesReceived: data['bytes_received'] ?? 0,
          clientIp: data['client_ip'],
          serverAddress: data['server_address'],
          serverPort: data['server_port'],
          connectedAt: DateTime.now(),
        );

        _startStatsUpdates();
      } else {
        throw Exception(response.message ?? 'Failed to connect to VPN');
      }
    } catch (e) {
      state = state.copyWith(
        status: 'error',
        error: e.toString(),
      );
      rethrow;
    }
  }

  Future<void> disconnect() async {
    try {
      state = state.copyWith(status: 'disconnecting');

      // Notify server
      final response = await _apiClient.disconnect();
      if (response.status == 'success') {
        state = state.copyWith(
          status: 'disconnected',
          bytesSent: 0,
          bytesReceived: 0,
          clientIp: null,
          serverAddress: null,
          serverPort: null,
          connectedAt: null,
        );

        _stopStatsUpdates();

        // Clean up configuration file
        if (_configPath != null) {
          final file = File(_configPath!);
          if (await file.exists()) {
            await file.delete();
          }
          _configPath = null;
        }
      } else {
        throw Exception(response.message ?? 'Failed to disconnect from VPN');
      }
    } catch (e) {
      state = state.copyWith(
        status: 'error',
        error: e.toString(),
      );
    }
  }

  void _startStatsUpdates() {
    _statsTimer?.cancel();
    _statsTimer = Timer.periodic(const Duration(seconds: 30), (_) async {
      if (state.status == 'active') {
        try {
          // Update server with new statistics
          final response = await _apiClient.updateStats(
            bytesSent: state.bytesSent,
            bytesReceived: state.bytesReceived,
          );

          if (response.status == 'success') {
            final data = response.data;
            state = state.copyWith(
              bytesSent: data['bytes_sent'] ?? 0,
              bytesReceived: data['bytes_received'] ?? 0,
            );
          }
        } catch (e) {
          // Log error but don't update state
          print('Failed to update VPN statistics: $e');
        }
      }
    });
  }

  void _stopStatsUpdates() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  Future<String> _saveConfig(String config) async {
    final directory = await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/wg0.conf');
    await file.writeAsString(config);
    return file.path;
  }

  @override
  void dispose() {
    _stopStatsUpdates();
    super.dispose();
  }
} 
 
 
 
 
 
 
 