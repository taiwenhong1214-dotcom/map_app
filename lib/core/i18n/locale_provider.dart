import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localeProvider = NotifierProvider<LocaleNotifier, Locale>(() {
  return LocaleNotifier();
});

class LocaleNotifier extends Notifier<Locale> {
  @override
  Locale build() {
    return const Locale('zh', 'CN'); // Default to Chinese
  }

  void toggleLocale() {
    if (state.languageCode == 'zh') {
      state = const Locale('en', 'US');
    } else {
      state = const Locale('zh', 'CN');
    }
  }
}
