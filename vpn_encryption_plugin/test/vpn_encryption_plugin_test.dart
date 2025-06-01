import 'package:flutter_test/flutter_test.dart';
import 'package:vpn_encryption_plugin/vpn_encryption_plugin.dart';
import 'package:vpn_encryption_plugin/vpn_encryption_plugin_platform_interface.dart';
import 'package:vpn_encryption_plugin/vpn_encryption_plugin_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockVpnEncryptionPluginPlatform
    with MockPlatformInterfaceMixin
    implements VpnEncryptionPluginPlatform {

  @override
  Future<String?> getPlatformVersion() => Future.value('42');
}

void main() {
  final VpnEncryptionPluginPlatform initialPlatform = VpnEncryptionPluginPlatform.instance;

  test('$MethodChannelVpnEncryptionPlugin is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelVpnEncryptionPlugin>());
  });

  test('getPlatformVersion', () async {
    VpnEncryptionPlugin vpnEncryptionPlugin = VpnEncryptionPlugin();
    MockVpnEncryptionPluginPlatform fakePlatform = MockVpnEncryptionPluginPlatform();
    VpnEncryptionPluginPlatform.instance = fakePlatform;

    expect(await vpnEncryptionPlugin.getPlatformVersion(), '42');
  });
}
