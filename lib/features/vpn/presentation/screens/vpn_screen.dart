import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';import 'package:vpn_encryption_plugin/vpn_encryption_plugin.dart';
import '../../../network/presentation/providers/network_provider.dart';
import '../../../network/data/models/wifi_network.dart';
import '../../../network/data/models/network_analysis.dart';

final vpnPlugin = VpnEncryptionPlugin();

// Create a provider for the VPN state stream
final vpnStateStreamProvider = StreamProvider<VPNState>((ref) {
  return vpnPlugin.vpnState.handleError((error) {
    print('VPN state stream error: $error');
    return VPNState.error;
  });
});

final vpnStateProvider = StateNotifierProvider<VpnNotifier, VpnState>((ref) {
  return VpnNotifier(ref);
});

class VpnState {
  final bool isEnabled;
  final bool isLoading;
  final String? error;
  final String? currentNetwork;
  final VPNState vpnState;

  const VpnState({
    this.isEnabled = false,
    this.isLoading = false,
    this.error,
    this.currentNetwork,
    this.vpnState = VPNState.disconnected,
  });

  VpnState copyWith({
    bool? isEnabled,
    bool? isLoading,
    String? error,
    String? currentNetwork,
    VPNState? vpnState,
  }) {
    return VpnState(
      isEnabled: isEnabled ?? this.isEnabled,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      currentNetwork: currentNetwork ?? this.currentNetwork,
      vpnState: vpnState ?? this.vpnState,
    );
  }
}

class VpnNotifier extends StateNotifier<VpnState> {
  final Ref ref;
  StreamSubscription<VPNState>? _vpnStateSubscription;

  VpnNotifier(this.ref) : super(const VpnState()) {
    _initializeVpnState();
  }

  void _initializeVpnState() {
    // Cancel any existing subscription
    _vpnStateSubscription?.cancel();

    // Listen to VPN state changes using the stream provider
    ref.listen<AsyncValue<VPNState>>(
      vpnStateStreamProvider,
      (previous, next) {
        next.whenData((vpnState) {
          state = state.copyWith(
            vpnState: vpnState,
            isEnabled: vpnState == VPNState.connected,
            isLoading: vpnState == VPNState.connecting || vpnState == VPNState.disconnecting,
            error: vpnState == VPNState.error ? 'VPN connection error' : null,
          );
        });
      },
    );

    // Check initial VPN state
    _checkVpnState();
  }

  Future<void> _checkVpnState() async {
    try {
      final isActive = await vpnPlugin.isVpnActive();
      state = state.copyWith(
        isEnabled: isActive,
        vpnState: isActive ? VPNState.connected : VPNState.disconnected,
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to check VPN state: $e',
        vpnState: VPNState.error,
      );
    }
  }

  Future<void> toggleVpn() async {
    if (state.isLoading) return;

    try {
      state = state.copyWith(
        isLoading: true,
        error: null,
        vpnState: state.isEnabled ? VPNState.disconnecting : VPNState.connecting,
      );

      if (state.isEnabled) {
        await vpnPlugin.stopVpn();
      } else {
        // Request VPN permission if needed
        final hasPermission = await vpnPlugin.requestVpnPermission();
        if (!hasPermission) {
          throw VpnPermissionDeniedException('VPN permission denied');
        }
        await vpnPlugin.startVpn();
      }
    } on VpnPermissionDeniedException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'VPN permission denied: ${e.message}',
        vpnState: VPNState.error,
      );
    } on VpnServiceException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'VPN service error: ${e.message}',
        vpnState: VPNState.error,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Unexpected error: $e',
        vpnState: VPNState.error,
      );
    }
  }

  @override
  void dispose() {
    _vpnStateSubscription?.cancel();
    super.dispose();
  }
}

class VpnScreen extends ConsumerWidget {
  const VpnScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vpnState = ref.watch(vpnStateProvider);
    final networkState = ref.watch(networkProvider);
    print('Building VPN Screen - State: ${vpnState.vpnState}'); // Debug print

    return Scaffold(
      backgroundColor: Colors.blue.withOpacity(0.1),
      appBar: AppBar(
        title: const Text('VPN Protection'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'VPN Status',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),

                        ),
                        Switch(
                          value: vpnState.isEnabled,
                          onChanged: vpnState.isLoading
                              ? null
                              : (_) => ref
                                  .read(vpnStateProvider.notifier)
                                  .toggleVpn(),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (vpnState.isLoading)
                      const LinearProgressIndicator()
                    else if (vpnState.error != null)
                      Text(
                        vpnState.error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      )
                    else
                      Text(
                        _getStatusText(vpnState.vpnState),
                        style: TextStyle(
                          color: _getStatusColor(context, vpnState.vpnState),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (networkState.currentNetwork != null) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Current Network',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildNetworkCard(
                        context,
                        networkState.currentNetwork!,
                        ref,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'About VPN Protection',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'When enabled, this VPN service encrypts all your network traffic to protect your privacy and security on public Wi-Fi networks.',
                    ),
                    SizedBox(height: 8),
                    Text(
                      '• Encrypts all network traffic\n'
                      '• Protects against network attacks\n'
                      '• Hides your IP address\n'
                      '• Secures your data on public networks\n'
                      '• Runs in background for continuous protection',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrustIndicator(NetworkAnalysis? analysis, NetworkCheck? check, bool isAnalyzing) {
    if (isAnalyzing) {
      return const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    if (analysis == null) {
      return const Icon(Icons.help_outline, color: Colors.grey);
    }

    final Color color;
    final IconData icon;
    final String tooltip;

    if (analysis.isTrusted) {
      color = Colors.green;
      icon = Icons.check_circle;
      tooltip = 'Trusted Network';
    } else if (analysis.isSuspicious) {
      color = Colors.red;
      icon = Icons.warning;
      tooltip = 'Suspicious Network';
    } else {
      color = Colors.orange;
      icon = Icons.warning_amber;
      tooltip = 'Untrusted Network';
    }

    return Tooltip(
      message: tooltip,
      child: Icon(icon, color: color),
    );
  }

  Widget _buildNetworkCard(BuildContext context, WifiNetwork network, WidgetRef ref) {
    final state = ref.read(networkProvider);
    final analysis = state.networkAnalysis[network.bssid];
    final check = state.networkChecks[network.bssid];

    return Card(
      margin: const EdgeInsets.symmetric(
        horizontal: 0.0,
        vertical: 4.0,
      ),
      child: ListTile(
        leading: Icon(
          Icons.wifi,
          color: network.isSecure
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.error,
        ),
        title: Text(network.ssid),
        subtitle: Text(
          'Signal: ${network.signalStrength} dBm\n'
          'Security: ${network.securityType ?? 'Unknown'}',
        ),
        trailing: _buildTrustIndicator(
          analysis,
          check,
          state.isAnalyzing,
        ),
      ),
    );
  }

  String _getStatusText(VPNState state) {
    switch (state) {
      case VPNState.connected:
        return 'VPN is protecting your connection';
      case VPNState.connecting:
        return 'Connecting to VPN...';
      case VPNState.disconnecting:
        return 'Disconnecting from VPN...';
      case VPNState.error:
        return 'VPN connection error';
      case VPNState.disconnected:
        return 'VPN is disabled';
    }
  }

  Color _getStatusColor(BuildContext context, VPNState state) {
    switch (state) {
      case VPNState.connected:
        return Theme.of(context).colorScheme.primary;
      case VPNState.connecting:
      case VPNState.disconnecting:
        return Theme.of(context).colorScheme.secondary;
      case VPNState.error:
        return Theme.of(context).colorScheme.error;
      case VPNState.disconnected:
        return Theme.of(context).colorScheme.onSurface;
    }
  }
} 
