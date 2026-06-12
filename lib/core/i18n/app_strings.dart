import 'package:flutter/material.dart';

class AppStrings {
  final Locale locale;
  AppStrings(this.locale);

  bool get isEn => locale.languageCode == 'en';

  String get appName => isEn ? 'Circular Travel' : '圆周旅迹';
  
  // Planner Page
  String get backToHome => isEn ? 'Home' : '首页';
  String get reGenerate => isEn ? 'Replan' : '重新规划';
  String get share => isEn ? 'Share' : '分享';
  String get day => isEn ? 'Day' : '第';
  String get daySuffix => isEn ? '' : ' 天';
  String get scanningMemories => isEn ? 'Scanning photo footprints...' : '正在扫描相册足迹...';
  String get noMemories => isEn ? 'No photo footprints found' : '未发现匹配的足迹照片';
  String get memoriesLit => isEn ? 'Successfully lit up {0} memories!' : '成功点亮 {0} 张回忆！';
  String get generatingPoster => isEn ? 'Generating poster...' : '正在生成专属长图...';
  String get posterFailed => isEn ? 'Failed to generate poster' : '长图生成失败，请重试';

  // AI Generation Form
  String get formTitle => isEn ? 'Where to next?' : '你的下一站，想去哪里？';
  String get destinationLabel => isEn ? 'Destination (e.g. Kyoto)' : '目的地 (如：京都)';
  String get daysLabel => isEn ? 'Days (e.g. 3)' : '天数 (如：3)';
  String get prefsLabel => isEn ? 'Preferences (e.g. foodie, culture)' : '偏好 (如：咖啡馆、美术馆、不要爬山)';
  String get generateBtn => isEn ? 'Plan My Trip' : '生成魔法行程';

  // Traffic
  String get trafficLoading => isEn ? '⏳ Calculating route...' : '⏳ 智能交通计算中...';
  String get trafficLocal => isEn ? '📍 Local fallback route' : '📍 本地测算完成';
  String trafficInfo(int durationMin, String distanceKm) => 
      isEn ? '🚗 Drive $durationMin min ($distanceKm km)' : '🚗 驾车 $durationMin 分钟 ($distanceKm km)';

  // Default Form Inputs
  String get defaultDest => isEn ? 'Tokyo' : '东京';
  String get defaultDays => '3';
  String get defaultPrefs => isEn ? 'Love niche cafes, anime culture, slow pace.' : '喜欢小众咖啡馆、二次元、吃寿喜烧，节奏慢一点';

  // AI Prompt Language
  String get aiLanguageInstruction => isEn ? 'You MUST respond entirely in English.' : '你必须完全使用中文（简体）进行回复。';

  // Copilot Chat
  String get copilotFab => isEn ? 'AI Copilot' : 'AI 伴游';
  String get copilotTitle => isEn ? '✨ How would you like to adjust the itinerary?' : '✨ 想要如何调整行程？';
  String get copilotSubtitle => isEn ? 'Example: "Change day 1 afternoon to a cafe" or "Remove some attractions"' : '例如："把第一天下午改成去喝咖啡" 或 "删掉几个景点"';
  String get copilotHint => isEn ? 'Enter your thoughts...' : '输入你的想法...';

  // Lottie Loading
  String get aiLoading => isEn ? '✨ AI is checking the weather and planning your magical trip...' : '✨ AI 正在查询当地天气并光速规划你的专属行程...';
}

extension AppStringsExt on BuildContext {
  AppStrings strings(Locale locale) => AppStrings(locale);
}
