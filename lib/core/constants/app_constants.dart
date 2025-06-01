class AppConstants {
  // App Info
  static const String appName = 'PubWIFI Protector';
  static const String appVersion = '1.0.0';
  
  // Routes
  static const String splashRoute = '/';
  static const String onboardingRoute = '/onboarding';
  static const String loginRoute = '/login';
  static const String registerRoute = '/register';
  static const String homeRoute = '/home';
  static const String networkRoute = '/network';
  static const String dnsRoute = '/dns';
  static const String sessionsRoute = '/sessions';
  static const String settingsRoute = '/settings';
  
  // Storage Keys
  static const String authTokenKey = 'auth_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userDataKey = 'user_data';
  static const String deviceIdKey = 'device_id';
  static const String onboardingCompletedKey = 'onboarding_completed';
  
  // API Endpoints
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000/api');
  static const int apiTimeout = 30000; // milliseconds
  
  // Network Constants
  static const int minSignalStrength = -100; // dBm
  static const int maxSignalStrength = -30; // dBm
  static const List<String> secureDnsProviders = [
    '1.1.1.1', // Cloudflare
    '8.8.8.8', // Google
    '9.9.9.9', // Quad9
  ];
  
  // Notification Channels
  static const String networkAlertsChannel = 'network_alerts';
  static const String dnsAlertsChannel = 'dns_alerts';
  static const String sessionAlertsChannel = 'session_alerts';
  
  // Error Messages
  static const String genericError = 'Something went wrong. Please try again.';
  static const String networkError = 'Please check your internet connection.';
  static const String authError = 'Authentication failed. Please login again.';
  static const String invalidCredentials = 'Invalid email or password.';
  static const String sessionExpired = 'Your session has expired. Please login again.';
  
  // Success Messages
  static const String loginSuccess = 'Successfully logged in.';
  static const String registerSuccess = 'Account created successfully.';
  static const String logoutSuccess = 'Successfully logged out.';
  static const String networkReportSuccess = 'Network report submitted successfully.';
  static const String dnsCheckSuccess = 'Domain check completed.';
  
  // Validation Messages
  static const String emailRequired = 'Email is required.';
  static const String invalidEmail = 'Please enter a valid email address.';
  static const String passwordRequired = 'Password is required.';
  static const String passwordMinLength = 'Password must be at least 8 characters.';
  static const String passwordMismatch = 'Passwords do not match.';
  
  // Feature Flags
  static const bool enableDnsProtection = true;
  static const bool enableNetworkMonitoring = true;
  static const bool enableNotifications = true;
} 