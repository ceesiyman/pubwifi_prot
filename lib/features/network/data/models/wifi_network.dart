class WifiNetwork {
  final String ssid;
  final String bssid;
  final int signalStrength;
  final String? securityType;
  final bool isSecure;
  final bool isCurrentNetwork;

  const WifiNetwork({
    required this.ssid,
    required this.bssid,
    required this.signalStrength,
    this.securityType,
    required this.isSecure,
    this.isCurrentNetwork = false,
  });

  WifiNetwork copyWith({
    String? ssid,
    String? bssid,
    int? signalStrength,
    String? securityType,
    bool? isSecure,
    bool? isCurrentNetwork,
  }) {
    return WifiNetwork(
      ssid: ssid ?? this.ssid,
      bssid: bssid ?? this.bssid,
      signalStrength: signalStrength ?? this.signalStrength,
      securityType: securityType ?? this.securityType,
      isSecure: isSecure ?? this.isSecure,
      isCurrentNetwork: isCurrentNetwork ?? this.isCurrentNetwork,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ssid': ssid,
      'bssid': bssid,
      'signal_strength': signalStrength,
      'encryption_type': securityType ?? 'Unknown',
      'is_secure': isSecure,
      'is_current_network': isCurrentNetwork,
    };
  }

  factory WifiNetwork.fromJson(Map<String, dynamic> json) {
    return WifiNetwork(
      ssid: json['ssid'] as String,
      bssid: json['bssid'] as String,
      signalStrength: json['signal_strength'] as int,
      securityType: json['encryption_type'] as String?,
      isSecure: json['is_secure'] as bool? ?? true,
      isCurrentNetwork: json['is_current_network'] as bool? ?? false,
    );
  }
} 