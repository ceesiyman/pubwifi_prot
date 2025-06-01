import 'dart:async';
import 'dart:convert';
import 'dart:ui';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:flutter_background_service_android/flutter_background_service_android.dart';
import 'package:flutter_background_service_ios/flutter_background_service_ios.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'network_analysis_service.dart';
import 'network_alert_service.dart';

class BackgroundNetworkService {
  static final BackgroundNetworkService _instance = BackgroundNetworkService._internal();
  factory BackgroundNetworkService() => _instance;
  BackgroundNetworkService._internal();

  final FlutterBackgroundService _backgroundService = FlutterBackgroundService();
  final NetworkInfo _networkInfo = NetworkInfo();
  final NetworkAnalysisService _analysisService = NetworkAnalysisService();
  final NetworkAlertService _alertService = NetworkAlertService();
  static const String _serviceId = 'network_monitor_service';

  Future<void> initialize() async {
    // Initialize background service
    await _backgroundService.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: onStart,
        autoStart: false,
        isForegroundMode: true,
        notificationChannelId: 'network_monitor_channel',
        initialNotificationTitle: 'Network Monitor',
        initialNotificationContent: 'Monitoring network security',
        foregroundServiceNotificationId: 888,
      ),
      iosConfiguration: IosConfiguration(
        autoStart: false,
        onForeground: onStart,
        onBackground: onIosBackground,
      ),
    );

    // Initialize alert service
    await _alertService.initialize();
  }

  Future<bool> onIosBackground(ServiceInstance service) async {
    return true;
  }

  @pragma('vm:entry-point')
  void onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    // Start periodic network check
    Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          await _checkNetworkStatus(service);
        }
      } else {
        await _checkNetworkStatus(service);
      }
    });
  }

  Future<void> _checkNetworkStatus(ServiceInstance service) async {
    try {
      final currentSSID = await _networkInfo.getWifiName();
      final currentBSSID = await _networkInfo.getWifiBSSID();

      if (currentSSID == null || currentBSSID == null) {
        return; // Not connected to any network
      }

      // Get last checked network from preferences
      final prefs = await SharedPreferences.getInstance();
      final lastCheckedSSID = prefs.getString('last_checked_ssid');
      final lastCheckedBSSID = prefs.getString('last_checked_bssid');

      // Only check if network changed or it's been more than 5 minutes
      if (lastCheckedSSID == currentSSID && 
          lastCheckedBSSID == currentBSSID &&
          DateTime.now().difference(
            DateTime.fromMillisecondsSinceEpoch(
              prefs.getInt('last_check_time') ?? 0
            )
          ).inMinutes < 5) {
        return;
      }

      // Perform network analysis
      final analysis = await _analysisService.analyzeNetwork(
        ssid: currentSSID.replaceAll('"', ''),
        bssid: currentBSSID.replaceAll('"', ''),
        signalStrength: -50, // Default value as we can't get it in background
        securityType: 'Unknown', // Default value as we can't get it in background
      );

      // Update last checked network
      await prefs.setString('last_checked_ssid', currentSSID);
      await prefs.setString('last_checked_bssid', currentBSSID);
      await prefs.setInt('last_check_time', DateTime.now().millisecondsSinceEpoch);

      // Show appropriate alert
      if (!analysis.isTrusted || analysis.isSuspicious) {
        await _alertService.showUnsafeNetworkAlert(
          ssid: currentSSID.replaceAll('"', ''),
          bssid: currentBSSID.replaceAll('"', ''),
          trustScore: analysis.trustScore,
          warnings: analysis.warnings,
        );
      } else {
        await _alertService.showNetworkStatusUpdate(
          ssid: currentSSID.replaceAll('"', ''),
          isTrusted: analysis.isTrusted,
          trustScore: analysis.trustScore,
        );
      }

      // Update service notification
      if (service is AndroidServiceInstance) {
        service.setForegroundNotificationInfo(
          title: "Network Monitor",
          content: "Monitoring: ${currentSSID.replaceAll('"', '')}\n"
              "Trust Score: ${analysis.trustScore}%",
        );
      }
    } catch (e) {
      print('Error in background network check: $e');
    }
  }

  Future<void> startService() async {
    await _backgroundService.startService();
  }

  Future<void> stopService() async {
    try {
      _backgroundService.invoke('stopService');
    } catch (e) {
      print('Error stopping service: $e');
    }
  }

  Future<bool> isServiceRunning() async {
    return await _backgroundService.isRunning();
  }
} 