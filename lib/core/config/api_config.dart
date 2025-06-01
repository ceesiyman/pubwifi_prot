import 'package:flutter_dotenv/flutter_dotenv.dart';

class ApiConfig {
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000';
  static int get timeout => int.parse(dotenv.env['API_TIMEOUT'] ?? '30000');
} 