import 'dart:async';
import 'package:flutter/services.dart';

class VpnEncryptionPlugin {
  static const MethodChannel _channel = MethodChannel('vpn_encryption_plugin');
  static const EventChannel _vpnStateChannel = EventChannel('vpn_encryption_plugin/state');

  static final VpnEncryptionPlugin _instance = VpnEncryptionPlugin._internal();
  factory VpnEncryptionPlugin() => _instance;
  VpnEncryptionPlugin._internal();

  Stream<VPNState>? _vpnStateStream;

  /// Stream of VPN state changes
  Stream<VPNState> get vpnState {
    _vpnStateStream ??= _vpnStateChannel
        .receiveBroadcastStream()
        .map((state) => VPNState.values[state as int]);
    return _vpnStateStream!;
  }

  /// Starts the VPN service.
  /// 
  /// This will:
  /// 1. Request VPN permission if not granted
  /// 2. Start the VPN service
  /// 3. Return true if successful, false otherwise
  /// 
  /// Throws a [PlatformException] if:
  /// - VPN permission is denied
  /// - Service fails to start
  Future<bool> startVpn() async {
    try {
      final result = await _channel.invokeMethod<bool>('startVpn');
      return result ?? false;
    } on PlatformException catch (e) {
      if (e.code == 'VPN_PERMISSION_DENIED') {
        throw VpnPermissionDeniedException(e.message ?? 'VPN permission denied');
      }
      throw VpnServiceException(e.message ?? 'Failed to start VPN service');
    }
  }

  /// Stops the VPN service.
  /// 
  /// Returns true if the service was stopped successfully.
  /// 
  /// Throws a [PlatformException] if the service fails to stop.
  Future<void> stopVpn() async {
    try {
      await _channel.invokeMethod('stopVpn');
    } on PlatformException catch (e) {
      throw VpnServiceException(e.message ?? 'Failed to stop VPN service');
    }
  }

  /// Check if VPN is currently active
  Future<bool> isVpnActive() async {
    try {
      final result = await _channel.invokeMethod<bool>('isVpnActive');
      return result ?? false;
    } on PlatformException catch (e) {
      throw VpnServiceException(e.message ?? 'Failed to check VPN status');
    }
  }

  /// Request VPN permissions
  Future<bool> requestVpnPermission() async {
    try {
      final result = await _channel.invokeMethod<bool>('requestVpnPermission');
      return result ?? false;
    } on PlatformException catch (e) {
      throw VpnPermissionDeniedException(e.message ?? 'Failed to request VPN permission');
    }
  }
}

enum VPNState {
  disconnected,
  connecting,
  connected,
  disconnecting,
  error
}

/// Exception thrown when VPN permission is denied by the user.
class VpnPermissionDeniedException implements Exception {
  final String message;
  VpnPermissionDeniedException(this.message);

  @override
  String toString() => 'VpnPermissionDeniedException: $message';
}

/// Exception thrown when VPN service operations fail.
class VpnServiceException implements Exception {
  final String message;
  VpnServiceException(this.message);

  @override
  String toString() => 'VpnServiceException: $message';
}
