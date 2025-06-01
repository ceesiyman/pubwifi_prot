import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class VpnStatsCard extends StatelessWidget {
  final int bytesSent;
  final int bytesReceived;
  final DateTime? connectedSince;

  const VpnStatsCard({
    super.key,
    required this.bytesSent,
    required this.bytesReceived,
    this.connectedSince,
  });

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (hours > 0) {
      return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final duration = connectedSince != null
        ? now.difference(connectedSince!)
        : const Duration();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Connection Statistics',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStatItem(
                  'Upload',
                  _formatBytes(bytesSent),
                  Icons.upload,
                ),
                _buildStatItem(
                  'Download',
                  _formatBytes(bytesReceived),
                  Icons.download,
                ),
                _buildStatItem(
                  'Duration',
                  _formatDuration(duration),
                  Icons.timer,
                ),
              ],
            ),
            if (connectedSince != null) ...[
              const SizedBox(height: 8),
              Text(
                'Connected since ${DateFormat('HH:mm:ss').format(connectedSince!)}',
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.grey),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.grey,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
} 
 
 
 
 
 
 