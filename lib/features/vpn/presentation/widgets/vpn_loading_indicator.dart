import 'package:flutter/material.dart';

class VpnLoadingIndicator extends StatelessWidget {
  const VpnLoadingIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Please wait...'),
        ],
      ),
    );
  }
} 
 
 
 
 
 
 