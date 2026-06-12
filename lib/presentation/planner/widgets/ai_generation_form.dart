import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/planner_providers.dart';

class AiGenerationForm extends ConsumerStatefulWidget {
  const AiGenerationForm({super.key});

  @override
  ConsumerState<AiGenerationForm> createState() => _AiGenerationFormState();
}

class _AiGenerationFormState extends ConsumerState<AiGenerationForm> {
  final _destController = TextEditingController(text: '东京');
  final _daysController = TextEditingController(text: '3');
  final _prefController = TextEditingController(text: '喜欢小众咖啡馆、二次元、吃寿喜烧，节奏慢一点');

  @override
  void dispose() {
    _destController.dispose();
    _daysController.dispose();
    _prefController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus(); // 收起键盘
    final days = int.tryParse(_daysController.text) ?? 3;
    ref.read(currentItineraryProvider.notifier).generate(
          _destController.text,
          days,
          _prefController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '🌟 告诉 AI 你的想法',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _destController,
            decoration: InputDecoration(
              labelText: '目的地',
              prefixIcon: const Icon(Icons.flight_takeoff),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _daysController,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              labelText: '游玩天数',
              prefixIcon: const Icon(Icons.calendar_month),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _prefController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: '旅行偏好 (越具体越好)',
              alignLabelWithHint: true,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('一键生成行程', style: TextStyle(fontSize: 16)),
          ),
        ],
      ),
    );
  }
}