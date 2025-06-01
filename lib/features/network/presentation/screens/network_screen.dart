import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../providers/network_provider.dart';
import '../../data/models/wifi_network.dart';
import '../../data/models/network_analysis.dart';

class NetworkScreen extends ConsumerStatefulWidget {
  const NetworkScreen({super.key});

  @override
  ConsumerState<NetworkScreen> createState() => _NetworkScreenState();
}

class _NetworkScreenState extends ConsumerState<NetworkScreen> {
  Future<void> _refreshNetworks() async {
    await ref.read(networkProvider.notifier).scanNetworks();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(networkProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('WiFi Networks'),
        actions: [
          // Add monitoring toggle
          IconButton(
            icon: Icon(
              state.isMonitoring ? Icons.security : Icons.security_outlined,
              color: state.isMonitoring ? Colors.green : null,
            ),
            onPressed: () {
              if (state.isMonitoring) {
                ref.read(networkProvider.notifier).stopMonitoring();
              } else {
                ref.read(networkProvider.notifier).startMonitoring();
              }
            },
            tooltip: state.isMonitoring ? 'Stop Monitoring' : 'Start Monitoring',
          ),
          // Existing refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: state.isLoading ? null : _refreshNetworks,
          ),
        ],
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        state.error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshNetworks,
                      child: const Text('Retry'),
                    ),
                  ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _refreshNetworks,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (state.isMonitoring)
                        Card(
                          color: Colors.green.withOpacity(0.1),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Row(
                              children: [
                                const Icon(Icons.security, color: Colors.green),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Network Monitoring Active',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'You will be notified about network security status',
                                        style: TextStyle(
                                          color: Colors.green.withOpacity(0.8),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () => ref
                                      .read(networkProvider.notifier)
                                      .stopMonitoring(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (state.currentNetwork != null) ...[
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
                          state.currentNetwork!,
                          ref,
                        ),
                        const SizedBox(height: 24),
                      ],
                      const Text(
                        'Available Networks',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (state.availableNetworks.isEmpty)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32),
                            child: Text(
                              'No networks found.\nMake sure WiFi is enabled and try again.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
              ),
            )
          else
                        ...state.availableNetworks
                            .where((network) =>
                                network.ssid != state.currentNetwork?.ssid)
                            .map((network) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: _buildNetworkCard(
                                    context,
                                    network,
                                    ref,
                                  ),
                                )),
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

  void _showNetworkInfo(BuildContext context, WifiNetwork network, WidgetRef ref) {
    final networkState = ref.read(networkProvider);
    final analysis = networkState.networkAnalysis[network.bssid];
    final check = networkState.networkChecks[network.bssid];
    final isAnalyzing = networkState.isAnalyzing;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Expanded(child: Text(network.ssid)),
            _buildTrustIndicator(analysis, check, isAnalyzing),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Signal Strength: ${network.signalStrength} dBm'),
              Text('Security: ${network.securityType ?? 'Unknown'}'),
              Text('BSSID: ${network.bssid}'),
              if (isAnalyzing) ...[
                const Divider(),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Analyzing network...'),
                  ),
                ),
              ] else if (analysis != null) ...[
                const Divider(),
                Text(
                  'Trust Score: ${analysis.trustScore}%',
                  style: TextStyle(
                    color: analysis.isTrusted ? Colors.green : Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (analysis.warnings.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Warnings:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...analysis.warnings.map((w) => Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text('• $w'),
                  )),
                ],
                if (analysis.recommendations.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Recommendations:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...analysis.recommendations.map((r) => Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text('• $r'),
                  )),
                ],
              ],
              if (check != null) ...[
                const Divider(),
                Text(
                  'Safety Status: ${check.isSafe ? 'Safe' : 'Unsafe'}',
                  style: TextStyle(
                    color: check.isSafe ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (check.warnings.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Text('Safety Warnings:', style: TextStyle(fontWeight: FontWeight.bold)),
                  ...check.warnings.map((w) => Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Text('• $w'),
                  )),
                ],
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkCard(BuildContext context, WifiNetwork network, WidgetRef ref) {
    final state = ref.read(networkProvider);
    final analysis = state.networkAnalysis[network.bssid];
    final check = state.networkChecks[network.bssid];

                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16.0,
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
        onTap: () => _showNetworkInfo(context, network, ref),
      ),
    );
  }
} 