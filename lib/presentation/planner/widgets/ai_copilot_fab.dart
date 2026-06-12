import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/i18n/locale_provider.dart';
import '../../../core/i18n/app_strings.dart';

class AiCopilotFab extends ConsumerWidget {
  final VoidCallback onTap;

  const AiCopilotFab({super.key, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final strings = context.strings(locale);

    return FloatingActionButton.extended(
      onPressed: onTap,
      backgroundColor: const Color(0xFF4A90E2),
      icon: const Icon(Icons.auto_awesome, color: Colors.white),
      label: Text(
        strings.copilotFab,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}