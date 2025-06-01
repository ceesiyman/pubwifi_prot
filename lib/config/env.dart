import 'package:flutter_dotenv/flutter_dotenv.dart';

class Env {
  static String get apiUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  static String get apiTimeout => dotenv.env['API_TIMEOUT'] ?? '30000';
  static String get appName => dotenv.env['APP_NAME'] ?? 'PubWIFI Protector';
  static String get appVersion => dotenv.env['APP_VERSION'] ?? '1.0.0';
  static String get appBuildNumber => dotenv.env['APP_BUILD_NUMBER'] ?? '1';
  static String get appEnvironment => dotenv.env['APP_ENVIRONMENT'] ?? 'development';
  static bool get isDevelopment => appEnvironment == 'development';
  static bool get isProduction => appEnvironment == 'production';
  static bool get isStaging => appEnvironment == 'staging';
  static bool get isTesting => appEnvironment == 'testing';
} 