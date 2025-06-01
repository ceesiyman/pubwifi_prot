class NetworkAnalysis {
  final String ssid;
  final String bssid;
  final int signalStrength;
  final String encryptionType;
  final int channel;
  final bool isTrusted;
  final bool isSuspicious;
  final int trustScore;
  final List<String> warnings;
  final List<String> recommendations;

  NetworkAnalysis({
    required this.ssid,
    required this.bssid,
    required this.signalStrength,
    required this.encryptionType,
    required this.channel,
    required this.isTrusted,
    required this.isSuspicious,
    required this.trustScore,
    required this.warnings,
    this.recommendations = const [],
  });

  factory NetworkAnalysis.fromJson(Map<String, dynamic> json) {
    return NetworkAnalysis(
      ssid: json['ssid'] as String,
      bssid: json['bssid'] as String,
      signalStrength: json['signal_strength'] as int,
      encryptionType: json['encryption_type'] as String,
      channel: json['channel'] as int,
      isTrusted: json['is_trusted'] as bool,
      isSuspicious: json['is_suspicious'] as bool,
      trustScore: json['trust_score'] as int,
      warnings: List<String>.from(json['warnings'] as List),
      recommendations: json['recommendations'] != null 
          ? List<String>.from(json['recommendations'] as List)
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ssid': ssid,
      'bssid': bssid,
      'signal_strength': signalStrength,
      'encryption_type': encryptionType,
      'channel': channel,
      'is_trusted': isTrusted,
      'is_suspicious': isSuspicious,
      'trust_score': trustScore,
      'warnings': warnings,
      'recommendations': recommendations,
    };
  }
}

class NetworkCheck {
  final bool isSafe;
  final int trustScore;
  final List<String> warnings;
  final bool isTrusted;
  final bool isSuspicious;

  NetworkCheck({
    required this.isSafe,
    required this.trustScore,
    required this.warnings,
    required this.isTrusted,
    required this.isSuspicious,
  });

  factory NetworkCheck.fromJson(Map<String, dynamic> json) {
    return NetworkCheck(
      isSafe: json['is_safe'] as bool,
      trustScore: json['trust_score'] as int,
      warnings: List<String>.from(json['warnings'] as List),
      isTrusted: json['is_trusted'] as bool,
      isSuspicious: json['is_suspicious'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'is_safe': isSafe,
      'trust_score': trustScore,
      'warnings': warnings,
      'is_trusted': isTrusted,
      'is_suspicious': isSuspicious,
    };
  }
} 