import 'package:flutter/material.dart';

class VpnErrorDialog extends StatelessWidget {
  final String title;
  final String message;

  const VpnErrorDialog({
    super.key,
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
} 
 
 
 
 
 
 