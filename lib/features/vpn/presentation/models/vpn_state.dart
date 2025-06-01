class VpnState {
  final String status;
  final String? error;
  final int bytesSent;
  final int bytesReceived;
  final String? clientIp;
  final String? serverAddress;
  final int? serverPort;
  final DateTime? connectedAt;

  const VpnState({
    this.status = 'disconnected',
    this.error,
    this.bytesSent = 0,
    this.bytesReceived = 0,
    this.clientIp,
    this.serverAddress,
    this.serverPort,
    this.connectedAt,
  });

  VpnState copyWith({
    String? status,
    String? error,
    int? bytesSent,
    int? bytesReceived,
    String? clientIp,
    String? serverAddress,
    int? serverPort,
    DateTime? connectedAt,
  }) {
    return VpnState(
      status: status ?? this.status,
      error: error,
      bytesSent: bytesSent ?? this.bytesSent,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      clientIp: clientIp ?? this.clientIp,
      serverAddress: serverAddress ?? this.serverAddress,
      serverPort: serverPort ?? this.serverPort,
      connectedAt: connectedAt ?? this.connectedAt,
    );
  }

  bool get isConnected => status == 'active';
  bool get isConnecting => status == 'connecting';
  bool get isDisconnecting => status == 'disconnecting';
  bool get hasError => error != null;
} 
 
 
 
 
 
 