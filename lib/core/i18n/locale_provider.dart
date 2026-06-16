import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    // 根据系统语言自动决定：中文系统 -> 中文，其他 -> 英文
    final systemLocale = ui.PlatformDispatcher.instance.locale;
    if (systemLocale.languageCode == 'zh') {
      return const Locale('zh', 'CN');
    }
    return const Locale('en', 'US');
  }

  void toggleLocale() {
    if (state.languageCode == 'zh') {
      state = const Locale('en', 'US');
    } else {
      state = const Locale('zh', 'CN');
    }
  }
}
