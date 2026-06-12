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

  // Map Search
  String get searchPlaceholder => isEn ? 'Search any place to jump...' : '搜索任意地点以点亮足迹...';
  String get searchNotFound => isEn ? 'Location not found, please try another keyword' : '未找到该地点，请尝试换个关键词';

  // Traffic
  String get trafficLoading => isEn ? '⏳ Calculating route...' : '⏳ 智能交通计算中...';
  String get trafficLocal => isEn ? '📍 Local fallback route' : '📍 本地测算完成';
  String trafficInfo(int durationMin, String distanceKm) {
    if (isEn) {
      return '🚗 Drive $durationMin min ($distanceKm km)';
    } else {
      return '🚗 驾车 $durationMin 分钟 ($distanceKm km)';
    }
  }

  // --- Nav & Other Pages ---
  String get navPlanner => isEn ? 'AI Planner' : 'AI 规划';
  String get navDiscovery => isEn ? 'Discovery' : '社区发现';
  String get navMemories => isEn ? 'Memories' : '旅迹相册';
  
  String get discoveryTitle => isEn ? 'Discovery' : '发现';
  String get copyToPlanner => isEn ? 'Copy' : '一键复刻';
  String get itineraryCopied => isEn ? 'Itinerary copied! Go to AI Planner to view.' : '行程已复制！请前往"AI规划"查看。';
  String copiesCount(int count) => isEn ? '$count Copies' : '$count 人复刻';
  String get daysItinerary => isEn ? 'Days Itinerary' : '天行程';

  String get emptyMemories => isEn ? 'Empty' : '空空如也';
  String get startNewJourney => isEn ? 'Start a new journey now!' : '快去开启一段新的旅程吧！';
  String photosCount(int count) => isEn ? '$count Photos' : '$count 照片';
  String footprintsCount(int count) => isEn ? '$count Footprints' : '$count 个足迹点';
  String get viewedOnMap => isEn ? 'Viewed photo on map!' : '在地图上查看了照片!';

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
