class Log {
  static void info(String message, [Map<String, dynamic>? data]) {
    print('VPN [INFO] $message${data != null ? ' - $data' : ''}');
  }

  static void error(String message, [Map<String, dynamic>? data]) {
    print('VPN [ERROR] $message${data != null ? ' - $data' : ''}');
  }

  static void debug(String message, [Map<String, dynamic>? data]) {
    print('VPN [DEBUG] $message${data != null ? ' - $data' : ''}');
  }
} 