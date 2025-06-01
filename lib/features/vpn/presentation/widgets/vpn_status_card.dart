import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VpnStatusCard extends StatelessWidget {
  final String status;
  final String? clientIp;
  final String? serverAddress;
  final int? serverPort;
  final DateTime? connectedAt;
  final String? error;

  const VpnStatusCard({
    super.key,
    required this.status,
    this.clientIp,
    this.serverAddress,
    this.serverPort,
    this.connectedAt,
    this.error,
  });

  bool get isConnected => status == 'active';

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isConnected ? Icons.vpn_lock : Icons.vpn_lock_outlined,
                  color: _getStatusColor(status),
                  size: 32,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getStatusText(status),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (error != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          error!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (clientIp != null) ...[
              const SizedBox(height: 8),
              Text(
                'Client IP: $clientIp',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (serverAddress != null && serverPort != null) ...[
              const SizedBox(height: 4),
              Text(
                'Server: $serverAddress:$serverPort',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            if (connectedAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Connected since: ${DateFormat('MMM d, y HH:mm').format(connectedAt!)}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'connecting':
      case 'disconnecting':
        return Colors.orange;
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'active':
        return 'Connected';
      case 'connecting':
        return 'Connecting...';
      case 'disconnecting':
        return 'Disconnecting...';
      case 'error':
        return 'Error';
      default:
        return 'Disconnected';
    }
  }
} 
 
 
 
 
 
 