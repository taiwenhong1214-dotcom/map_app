import 'package:flutter/material.dart';

class AiCopilotFab extends StatelessWidget {
  final VoidCallback onTap;

  const AiCopilotFab({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: const Color(0xFF4A90E2),
      icon: const Icon(Icons.auto_awesome, color: Colors.white),
      label: const Text(
        'AI 伴游',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}