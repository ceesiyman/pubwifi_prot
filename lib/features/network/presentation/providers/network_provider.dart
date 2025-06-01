import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:developer' as developer;
import '../../data/models/wifi_network.dart';
import '../../data/services/network_analysis_service.dart';
import '../../data/models/network_analysis.dart';
import '../../data/services/network_alert_service.dart';
import '../../data/services/background_network_service.dart';
import 'dart:async';

class NetworkState {
  final WifiNetwork? currentNetwork;
  final List<WifiNetwork> availableNetworks;
  final bool isLoading;
  final String? error;
  final Map<String, NetworkAnalysis> networkAnalysis;
  final Map<String, NetworkCheck> networkChecks;
  final bool isAnalyzing;
  final bool isMonitoring;

  const NetworkState({
    this.currentNetwork,
    this.availableNetworks = const [],
    this.isLoading = false,
    this.error,
    this.networkAnalysis = const {},
    this.networkChecks = const {},
    this.isAnalyzing = false,
    this.isMonitoring = false,
  });

  NetworkState copyWith({
    WifiNetwork? currentNetwork,
    List<WifiNetwork>? availableNetworks,
    bool? isLoading,
    String? error,
    Map<String, NetworkAnalysis>? networkAnalysis,
    Map<String, NetworkCheck>? networkChecks,
    bool? isAnalyzing,
    bool? isMonitoring,
  }) {
    return NetworkState(
      currentNetwork: currentNetwork ?? this.currentNetwork,
      availableNetworks: availableNetworks ?? this.availableNetworks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      networkAnalysis: networkAnalysis ?? Map<String, NetworkAnalysis>.from(this.networkAnalysis),
      networkChecks: networkChecks ?? Map<String, NetworkCheck>.from(this.networkChecks),
      isAnalyzing: isAnalyzing ?? this.isAnalyzing,
      isMonitoring: isMonitoring ?? this.isMonitoring,
    );
  }
}

final networkProvider = StateNotifierProvider<NetworkNotifier, NetworkState>((ref) {
  return NetworkNotifier();
});

class NetworkNotifier extends StateNotifier<NetworkState> {
  final _networkInfo = NetworkInfo();
  final _wifiScan = WiFiScan.instance;
  final _analysisService = NetworkAnalysisService();
  final _alertService = NetworkAlertService();
  final _backgroundService = BackgroundNetworkService();
  Timer? _monitoringTimer;

  NetworkNotifier() : super(const NetworkState()) {
    _initializeWifi();
    _initializeBackgroundService();
  }

  Future<void> _initializeBackgroundService() async {
    await _backgroundService.initialize();
    final isRunning = await _backgroundService.isServiceRunning();
    if (isRunning) {
      state = state.copyWith(isMonitoring: true);
    }
  }

  @override
  void dispose() {
    _monitoringTimer?.cancel();
    super.dispose();
  }

  Future<bool> _checkAndRequestPermissions() async {
    try {
      // Check location permission (required for WiFi scanning)
      final locationStatus = await Permission.location.status;
      if (!locationStatus.isGranted) {
        final result = await Permission.location.request();
        if (!result.isGranted) {
          state = state.copyWith(
            error: 'Location permission is required for WiFi scanning',
          );
          return false;
        }
      }

      // For Android 12 and above, check nearby devices permission
      if (await Permission.nearbyWifiDevices.status != PermissionStatus.granted) {
        final result = await Permission.nearbyWifiDevices.request();
        if (!result.isGranted) {
        state = state.copyWith(
            error: 'Nearby devices permission is required for WiFi scanning',
          );
          return false;
        }
      }

      return true;
    } catch (e) {
      developer.log('Error checking permissions: $e', error: e);
      state = state.copyWith(error: 'Failed to check permissions: $e');
      return false;
    }
  }

  Future<void> _initializeWifi() async {
    try {
      // Check permissions first
      if (!await _checkAndRequestPermissions()) {
        return;
      }

      await _updateCurrentNetworkInfo();
      await scanNetworks();
    } catch (e) {
      developer.log('Error initializing WiFi: $e', error: e);
      state = state.copyWith(error: 'Failed to initialize WiFi: $e');
    }
  }

  Future<void> _updateCurrentNetworkInfo() async {
    try {
      final currentSSID = await _networkInfo.getWifiName();
      final currentBSSID = await _networkInfo.getWifiBSSID();
      developer.log('Current network - SSID: $currentSSID, BSSID: $currentBSSID');

      if (currentSSID != null && currentBSSID != null) {
        // Find the network in available networks or create a new one
        final network = state.availableNetworks.firstWhere(
          (n) => n.ssid == currentSSID.replaceAll('"', ''),
          orElse: () => WifiNetwork(
            ssid: currentSSID.replaceAll('"', ''),
            bssid: currentBSSID.replaceAll('"', ''),
            signalStrength: -50,
            isSecure: true,
            isCurrentNetwork: true,
          ),
        );

        state = state.copyWith(
          currentNetwork: network.copyWith(isCurrentNetwork: true),
        );

        // Analyze current network if not already analyzed
        if (!state.networkAnalysis.containsKey(network.bssid)) {
          await analyzeNetwork(network);
        }

        // If monitoring is active, check network status
        if (state.isMonitoring) {
          await _checkCurrentNetworkStatus();
        }
      } else {
        state = state.copyWith(currentNetwork: null);
      }
    } catch (e) {
      developer.log('Error updating current network info: $e', error: e);
    }
  }

  Future<void> analyzeNetwork(WifiNetwork network) async {
    if (state.isAnalyzing) return;

    try {
      state = state.copyWith(isAnalyzing: true);

      // First check if we already have analysis for this network
      if (state.networkAnalysis.containsKey(network.bssid)) {
        return;
      }

      developer.log('Analyzing network: ${network.ssid} (${network.bssid})');

      // Perform network analysis
      final analysis = await _analysisService.analyzeNetwork(
        ssid: network.ssid,
        bssid: network.bssid,
        signalStrength: network.signalStrength,
        securityType: network.securityType ?? 'Unknown',
      );

      // Update state with analysis results
      final updatedAnalysis = Map<String, NetworkAnalysis>.from(state.networkAnalysis);
      updatedAnalysis[network.bssid] = analysis;
      state = state.copyWith(
        networkAnalysis: updatedAnalysis,
        isAnalyzing: false,
      );

      // Also perform a network check
      await checkNetwork(network);
    } catch (e) {
      developer.log('Error analyzing network: $e', error: e);
      state = state.copyWith(
        isAnalyzing: false,
        error: 'Failed to analyze network: $e',
      );
    }
  }

  Future<void> checkNetwork(WifiNetwork network) async {
    try {
      // First check if we already have check results for this network
      if (state.networkChecks.containsKey(network.bssid)) {
        return;
      }

      developer.log('Checking network: ${network.ssid} (${network.bssid})');

      // Perform network check
      final check = await _analysisService.checkNetwork(
        ssid: network.ssid,
        bssid: network.bssid,
      );

      // Update state with check results
      final updatedChecks = Map<String, NetworkCheck>.from(state.networkChecks);
      updatedChecks[network.bssid] = check;
      state = state.copyWith(
        networkChecks: updatedChecks,
      );
    } catch (e) {
      developer.log('Error checking network: $e', error: e);
      // Don't update error state here to avoid overwriting analysis error
    }
  }

  Future<void> scanNetworks() async {
    try {
      // Check permissions first
      if (!await _checkAndRequestPermissions()) {
        return;
      }

      state = state.copyWith(isLoading: true, error: null);

      // Check if WiFi scanning is supported
      final canStartScan = await _wifiScan.canStartScan();
      developer.log('Can start scan: $canStartScan');
      
      if (canStartScan != CanStartScan.yes) {
        state = state.copyWith(
          isLoading: false,
          error: 'WiFi scanning is not available: $canStartScan',
        );
        return;
      }

      // Try to start scan with retry logic
      bool started = false;
      int retryCount = 0;
      const maxRetries = 3;

      while (!started && retryCount < maxRetries) {
        if (retryCount > 0) {
          developer.log('Retrying scan start attempt ${retryCount + 1}');
          await Future.delayed(const Duration(seconds: 1)); // Wait before retry
        }

        // Check if we can start a scan before attempting
        final canScan = await _wifiScan.canStartScan();
        if (canScan != CanStartScan.yes) {
          developer.log('Cannot start scan on retry attempt: $canScan');
          break;
        }

        started = await _wifiScan.startScan();
        developer.log('Scan start attempt ${retryCount + 1}: $started');
        
        if (!started) {
          retryCount++;
        }
      }
      
      if (!started) {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to start WiFi scan after $maxRetries attempts',
        );
        return;
      }

      // Wait a bit longer for scan to complete
      await Future.delayed(const Duration(seconds: 3));

      // Get scan results
      final results = await _wifiScan.getScannedResults();
      developer.log('Scan results count: ${results.length}');
      
      if (results.isEmpty) {
        developer.log('No networks found in scan results');
        state = state.copyWith(
          isLoading: false,
          error: 'No networks found in scan results',
        );
        return;
      }

      // Get current network info
      final currentSSID = await _networkInfo.getWifiName();
      final currentBSSID = await _networkInfo.getWifiBSSID();
      developer.log('Current network - SSID: $currentSSID, BSSID: $currentBSSID');

      // Convert scan results to WifiNetwork objects
      final networks = results.map((result) {
        final isCurrent = result.ssid == currentSSID?.replaceAll('"', '') &&
                         result.bssid == currentBSSID?.replaceAll('"', '');
        return WifiNetwork(
          ssid: result.ssid,
          bssid: result.bssid,
          signalStrength: result.level,
          securityType: _getSecurityType(result.capabilities),
          isSecure: result.capabilities.isNotEmpty,
          isCurrentNetwork: isCurrent,
        );
      }).toList();

      // Update state with new networks
      state = state.copyWith(
        availableNetworks: networks,
        isLoading: false,
      );

      // Update current network info
      await _updateCurrentNetworkInfo();

      // Analyze networks in the background
      for (final network in networks) {
        if (!state.networkAnalysis.containsKey(network.bssid)) {
          analyzeNetwork(network);
        }
      }
    } catch (e) {
      developer.log('Error scanning networks: $e', error: e);
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to scan networks: $e',
      );
    }
  }

  String? _getSecurityType(String capabilities) {
    if (capabilities.isEmpty) return 'Open';
    if (capabilities.contains('WPA3')) return 'WPA3';
    if (capabilities.contains('WPA2')) return 'WPA2';
    if (capabilities.contains('WPA')) return 'WPA';
    if (capabilities.contains('WEP')) return 'WEP';
    return 'Unknown';
  }

  Future<void> startMonitoring() async {
    if (state.isMonitoring) return;

    await _alertService.initialize();
    await _backgroundService.startService();
    state = state.copyWith(isMonitoring: true);

    // Check network status immediately
    await _checkCurrentNetworkStatus();

    // Set up periodic monitoring in the app
    _monitoringTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkCurrentNetworkStatus();
    });
  }

  Future<void> stopMonitoring() async {
    _monitoringTimer?.cancel();
    await _backgroundService.stopService();
    state = state.copyWith(isMonitoring: false);
  }

  Future<void> _checkCurrentNetworkStatus() async {
    try {
      final currentSSID = await _networkInfo.getWifiName();
      final currentBSSID = await _networkInfo.getWifiBSSID();

      if (currentSSID == null || currentBSSID == null) {
        return; // Not connected to any network
      }

      // Find or create current network
      final network = state.availableNetworks.firstWhere(
        (n) => n.ssid == currentSSID.replaceAll('"', ''),
        orElse: () => WifiNetwork(
          ssid: currentSSID.replaceAll('"', ''),
          bssid: currentBSSID.replaceAll('"', ''),
          signalStrength: -50,
          isSecure: true,
          isCurrentNetwork: true,
        ),
      );

      // Get or perform network analysis
      NetworkAnalysis? analysis = state.networkAnalysis[network.bssid];
      if (analysis == null) {
        analysis = await _analysisService.analyzeNetwork(
          ssid: network.ssid,
          bssid: network.bssid,
          signalStrength: network.signalStrength,
          securityType: network.securityType ?? 'Unknown',
        );
      }

      // Show appropriate alert based on network status
      if (!analysis.isTrusted || analysis.isSuspicious) {
        await _alertService.showUnsafeNetworkAlert(
          ssid: network.ssid,
          bssid: network.bssid,
          trustScore: analysis.trustScore,
          warnings: analysis.warnings,
        );
      } else {
        await _alertService.showNetworkStatusUpdate(
          ssid: network.ssid,
          isTrusted: analysis.isTrusted,
          trustScore: analysis.trustScore,
        );
      }

      // Update state with current network
      state = state.copyWith(
        currentNetwork: network.copyWith(isCurrentNetwork: true),
      );
    } catch (e) {
      developer.log('Error checking network status: $e', error: e);
    }
  }
} 