import 'package:flutter/material.dart';

/// Fully static connectivity check screen.
/// Makes zero backend calls — safe to hit before auth/config is verified.
class PingScreen extends StatelessWidget {
  const PingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.check_circle_outline, size: 72, color: Color(0xFF4CAF50)),
            SizedBox(height: 24),
            Text(
              'Hello, World!',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'If you can read this, the app is reachable.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
