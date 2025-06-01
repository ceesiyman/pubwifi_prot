import 'package:flutter_riverpod/flutter_riverpod.dart';

class VpnState {
  final String status;
  final DateTime? connectedAt;
  final DateTime? disconnectedAt;
  final int bytesSent;
  final int bytesReceived;

  VpnState({
    this.status = 'disconnected',
    this.connectedAt,
    this.disconnectedAt,
    this.bytesSent = 0,
    this.bytesReceived = 0,
  });

  VpnState copyWith({
    String? status,
    DateTime? connectedAt,
    DateTime? disconnectedAt,
    int? bytesSent,
    int? bytesReceived,
  }) {
    return VpnState(
      status: status ?? this.status,
      connectedAt: connectedAt ?? this.connectedAt,
      disconnectedAt: disconnectedAt ?? this.disconnectedAt,
      bytesSent: bytesSent ?? this.bytesSent,
      bytesReceived: bytesReceived ?? this.bytesReceived,
    );
  }
}

class VpnNotifier extends StateNotifier<VpnState> {
  VpnNotifier() : super(VpnState());

  void updateStatus(String status) {
    state = state.copyWith(
      status: status,
      connectedAt: status == 'active' ? DateTime.now() : state.connectedAt,
      disconnectedAt: status == 'disconnected' ? DateTime.now() : state.disconnectedAt,
    );
  }

  void updateStats({int? bytesSent, int? bytesReceived}) {
    state = state.copyWith(
      bytesSent: bytesSent,
      bytesReceived: bytesReceived,
    );
  }

  void reset() {
    state = VpnState();
  }
}

final vpnProvider = StateNotifierProvider<VpnNotifier, VpnState>((ref) {
  return VpnNotifier();
}); 
 
 
 
 
 
 