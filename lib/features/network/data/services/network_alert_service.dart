import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:developer' as developer;
import 'dart:convert';

class NetworkAlertService {
  static final NetworkAlertService _instance = NetworkAlertService._internal();
  factory NetworkAlertService() => _instance;
  NetworkAlertService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  static const int _networkAlertId = 1;

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request notification permissions
    await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.requestNotificationsPermission();
    await _notifications.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>()?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
  }

  void _onNotificationTapped(NotificationResponse response) {
    // Handle notification tap if needed
    developer.log('Network alert notification tapped: ${response.payload}');
  }

  Future<void> showUnsafeNetworkAlert({
    required String ssid,
    required String bssid,
    required int trustScore,
    required List<String> warnings,
  }) async {
    final channelId = dotenv.env['CHANNEL_NETWORK_ALERTS'] ?? 'network_alerts';
    
    // Create notification channel for Android
    const androidChannel = AndroidNotificationChannel(
      'network_alerts',
      'Network Alerts',
      description: 'Alerts about unsafe network connections',
      importance: Importance.high,
      enableVibration: true,
      playSound: true,
    );

    await _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>()?.createNotificationChannel(androidChannel);

    // Prepare notification details
    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Network Alerts',
      channelDescription: 'Alerts about unsafe network connections',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'Network Alert',
      styleInformation: BigTextStyleInformation(
        '⚠️ Unsafe Network Detected!\n\n'
        'Network: $ssid\n'
        'Trust Score: $trustScore%\n'
        'Warnings: ${warnings.join(", ")}',
        htmlFormatBigText: true,
        contentTitle: '⚠️ Unsafe Network Alert',
        htmlFormatContentTitle: true,
      ),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Show the notification
    await _notifications.show(
      _networkAlertId,
      '⚠️ Unsafe Network Alert',
      'You are connected to an unsafe network: $ssid\nTrust Score: $trustScore%\nWarnings: ${warnings.join(", ")}',
      details,
      payload: jsonEncode({
        'ssid': ssid,
        'bssid': bssid,
        'trust_score': trustScore,
        'warnings': warnings,
      }),
    );
  }

  Future<void> showNetworkStatusUpdate({
    required String ssid,
    required bool isTrusted,
    required int trustScore,
  }) async {
    final channelId = dotenv.env['CHANNEL_NETWORK_ALERTS'] ?? 'network_alerts';
    
    final androidDetails = AndroidNotificationDetails(
      channelId,
      'Network Status',
      channelDescription: 'Updates about network security status',
      importance: Importance.low,
      priority: Priority.low,
      styleInformation: BigTextStyleInformation(
        isTrusted
            ? '✅ Connected to trusted network: $ssid\nTrust Score: $trustScore%'
            : '⚠️ Connected to untrusted network: $ssid\nTrust Score: $trustScore%',
        htmlFormatBigText: true,
        contentTitle: isTrusted ? '✅ Network Status' : '⚠️ Network Status',
        htmlFormatContentTitle: true,
      ),
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: false,
    );

    final details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      _networkAlertId + 1,
      isTrusted ? '✅ Network Status' : '⚠️ Network Status',
      isTrusted
          ? 'Connected to trusted network: $ssid\nTrust Score: $trustScore%'
          : 'Connected to untrusted network: $ssid\nTrust Score: $trustScore%',
      details,
    );
  }
} 