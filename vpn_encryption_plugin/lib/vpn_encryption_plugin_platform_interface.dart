import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'vpn_encryption_plugin_method_channel.dart';

abstract class VpnEncryptionPluginPlatform extends PlatformInterface {
  /// Constructs a VpnEncryptionPluginPlatform.
  VpnEncryptionPluginPlatform() : super(token: _token);

  static final Object _token = Object();

  static VpnEncryptionPluginPlatform _instance = MethodChannelVpnEncryptionPlugin();

  /// The default instance of [VpnEncryptionPluginPlatform] to use.
  ///
  /// Defaults to [MethodChannelVpnEncryptionPlugin].
  static VpnEncryptionPluginPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [VpnEncryptionPluginPlatform] when
  /// they register themselves.
  static set instance(VpnEncryptionPluginPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
