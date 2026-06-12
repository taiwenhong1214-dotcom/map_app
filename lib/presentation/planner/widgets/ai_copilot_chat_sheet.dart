import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/planner_providers.dart';
import '../../../core/i18n/locale_provider.dart';
import '../../../core/i18n/app_strings.dart';

class AiCopilotChatSheet extends ConsumerStatefulWidget {
  const AiCopilotChatSheet({super.key});

  @override
  ConsumerState<AiCopilotChatSheet> createState() => _AiCopilotChatSheetState();
}

class _AiCopilotChatSheetState extends ConsumerState<AiCopilotChatSheet> {
  final _textController = TextEditingController();

  void _sendMsg() {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    // 关掉弹窗，让底层的页面显示 Loading 状态
    Navigator.of(context).pop();
    
    // 调用 Provider 方法发起微调
    ref.read(currentItineraryNotifierProvider.notifier).modifyItinerary(text);
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final strings = context.strings(locale);

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        // 适配键盘高度，防止键盘挡住输入框
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            strings.copilotTitle,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            strings.copilotSubtitle,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _textController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: strings.copilotHint,
                    filled: true,
                    fillColor: Theme.of(context).scaffoldBackgroundColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  onSubmitted: (_) => _sendMsg(),
                ),
              ),
              const SizedBox(width: 12),
              CircleAvatar(
                radius: 24,
                backgroundColor: const Color(0xFF4A90E2),
                child: IconButton(
                  icon: const Icon(Icons.send, color: Colors.white),
                  onPressed: _sendMsg,
                ),
              )
            ],
          )
        ],
      ),
    );
  }
}