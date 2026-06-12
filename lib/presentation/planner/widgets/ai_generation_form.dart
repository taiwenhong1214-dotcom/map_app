import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/planner_providers.dart';
import '../../../core/i18n/locale_provider.dart';
import '../../../core/i18n/app_strings.dart';

class AiGenerationForm extends ConsumerStatefulWidget {
  const AiGenerationForm({super.key});

  @override
  ConsumerState<AiGenerationForm> createState() => _AiGenerationFormState();
}

class _AiGenerationFormState extends ConsumerState<AiGenerationForm> {
  final _destController = TextEditingController();
  final _daysController = TextEditingController();
  final _prefController = TextEditingController();

  @override
  void dispose() {
    _destController.dispose();
    _daysController.dispose();
    _prefController.dispose();
    super.dispose();
  }

  void _submit(AppStrings strings) {
    FocusScope.of(context).unfocus(); // 收起键盘
    final dest = _destController.text.isNotEmpty ? _destController.text : strings.defaultDest;
    final daysStr = _daysController.text.isNotEmpty ? _daysController.text : strings.defaultDays;
    final days = int.tryParse(daysStr) ?? 3;
    final prefs = _prefController.text.isNotEmpty ? _prefController.text : strings.defaultPrefs;

    ref.read(currentItineraryNotifierProvider.notifier).generate(
          dest,
          days,
          prefs,
        );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final strings = context.strings(locale);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min, // 取消高度约束，让其自然包裹内容
            children: [
            Text(
              '🌟 ${strings.formTitle}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _destController,
            decoration: InputDecoration(
              labelText: strings.destinationLabel,
              prefixIcon: const Icon(Icons.flight_takeoff),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _daysController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: strings.daysLabel,
              prefixIcon: const Icon(Icons.calendar_month),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _prefController,
            minLines: 1,
            maxLines: 4,
            decoration: InputDecoration(
              labelText: strings.prefsLabel,
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: () => _submit(strings),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(strings.generateBtn, style: const TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }
}