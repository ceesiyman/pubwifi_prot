import 'package:flutter/material.dart';

class VpnToggle extends StatelessWidget {
  final bool isEnabled;
  final bool isLoading;
  final ValueChanged<bool> onToggle;

  const VpnToggle({
    super.key,
    required this.isEnabled,
    required this.isLoading,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'VPN Protection',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isEnabled ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: isEnabled ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Switch(
                  value: isEnabled,
                  onChanged: isLoading ? null : onToggle,
                  activeColor: Colors.green,
                ),
              ],
            ),
            if (isLoading) ...[
              const SizedBox(height: 8),
              const LinearProgressIndicator(),
            ],
          ],
        ),
      ),
    );
  }
} 
 
 
 
 
 
 