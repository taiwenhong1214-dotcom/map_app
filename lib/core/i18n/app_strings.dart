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
  String get save => isEn ? 'Save' : '保存';
  String get savedToLocal => isEn ? '💾 Saved to my trips!' : '💾 已保存到我的手账！';
  String get publishCommunity => isEn ? 'Publish' : '发布社区';

  // Publish Sheet
  String publishSheetTitle(String dest) => isEn ? 'My awesome trip to $dest' : '$dest 的奇妙之旅';
  String get enterTitlePrompt => isEn ? 'Please enter a title!' : '请输入标题！';
  String get defaultPostDesc => isEn ? 'Check out this amazing itinerary I generated using AI Planner!' : '快来看看我用 AI Planner 生成的魔法行程！';
  String get publishSuccess => isEn ? 'Published successfully! Check it out in Discovery.' : '发布成功！去"社区发现"看看吧！';
  String get publishSheetHeader => isEn ? 'Share to Community' : '分享至社区';
  String get titleHint => isEn ? 'A catchy title' : '取个响亮的标题';
  String get descHint => isEn ? 'What was the highlight of this trip...' : '说说这次行程的亮点吧...';
  String get publishBtn => isEn ? 'Publish Now' : '立即发布';
  String get setCoverPhoto => isEn ? 'Set Cover Photo (Optional)' : '设置封面照片 (可选)';

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
  String get addPhoto => isEn ? 'Add Photo' : '添加照片';
  String daysCount(int count) => isEn ? '$count Days' : '$count 天';
  String get photoPermissionRequired => isEn ? 'Photo access permission is required to add photos' : '需要相册权限才能添加照片';
  String get selectPhotoToComplete => isEn ? 'Select photo to complete footprint' : '选择照片补齐足迹';
  String get authorNameLabel => isEn ? 'Author Name' : '作者昵称';
  String get authorNameHint => isEn ? 'Everyone will see this name' : '大家都会看到这个名字哦';
  String get authorNameRequired => isEn ? 'Please enter author name' : '请输入作者昵称';
  String get avatarUploadFailed => isEn ? 'Failed to upload avatar' : '头像上传失败';
  String get avatarUploadFailedEmpty => isEn ? 'Failed to upload avatar (returned empty)' : '头像上传失败 (返回为空)';
  String get alreadyOnMap => isEn ? 'On Map' : '已在地图';
  
  // Community Feed Strings
  String get confirmDeleteTitle => isEn ? 'Confirm Delete' : '确认删除';
  String get confirmDeleteContent => isEn ? 'Are you sure you want to delete this post?' : '你确定要删除这篇分享吗？';
  String get cancel => isEn ? 'Cancel' : '取消';
  String get delete => isEn ? 'Delete' : '删除';
  String get copied => isEn ? 'Copied' : '已复制';

  // Poster Generator Strings
  String shareText(String destination) => isEn ? 'Check out my beautiful $destination itinerary!' : '快来看看我分享的 $destination 绝美行程，一键复刻！';
  String get generatePosterFailed => isEn ? 'Failed to generate poster, please try again.' : '生成长图失败，请重试';
  String get posterQuote => isEn ? '"The world is a book, and those who do not travel read only one page."' : '"世界是一本书，不旅行的人只读了其中一页"';

  // My Trips Strings
  String get myTripsTitle => isEn ? 'My Trips' : '我的 历史行程';
  String get emptyTrips => isEn ? 'You haven\'t saved any trips yet.\nGo plan your next adventure!' : '你还没有保存过行程\n快去规划一次说走就走的旅行吧！';

  // Live Tracking Strings
  String get joinRoomBtn => isEn ? 'Join Room' : '进房间';
  String get liveTrackingTitle => isEn ? 'Live Tracking' : '实时防走散 (Live Tracking)';
  String get liveTrackingDesc => isEn ? 'Share your live location with friends, never get lost again!' : '与好友共享实时位置，再也不怕在异国他乡走散啦！';
  String get yourInviteCode => isEn ? 'Your Exclusive Room Code' : '您的专属房间邀请码';
  String get startEnterRoomBtn => isEn ? 'Start & Enter Room' : '立即开启并进入房间';
  String get exitStopSharingBtn => isEn ? 'Exit & Stop Sharing' : '退出房间并停止共享';
  String get copyInviteCode => isEn ? 'Copy Invite Code' : '复制邀请口令发送给好友';
  String get inviteCopiedMsg => isEn ? 'Invite code copied!' : '邀请口令已复制！';
  String get exitRoomMsg => isEn ? 'Exited room, location sharing stopped' : '已退出房间，停止共享位置';
  String get joinLiveTrackingRoom => isEn ? 'Join Live Tracking Room' : '加入防走散房间';
  String get enterInviteCodeDesc => isEn ? 'Enter the 6-digit invite code from your friend' : '输入好友分享的 6 位房间邀请码';
  String get enterCodeHint => isEn ? 'Enter code' : '输入口令';
  String get enterRoomSubmitBtn => isEn ? 'Enter Room' : '进入房间';
  String inviteMessage(String code) => isEn 
    ? 'Hey! I started a Live Tracking room in Circular Travel. Use code [$code] to join me!' 
    : '嗨！我正在 Circular Travel 开启了防走散房间，邀请码是【$code】。快来加入我吧！';
  String get joinedDemoMsg => isEn ? '✅ Synced itinerary and joined room! (Demo)' : '✅ 已同步好友行程并加入房间！(Demo演示)';
  String get joinedRoomTitle => isEn ? '✅ Live Tracking enabled & Joined room: ' : '✅ 已开启防走散并加入房间: ';
  String get regenerateBtn => isEn ? 'Regenerate' : '重新生成';
  String get generateFailed => isEn ? 'Generation failed: ' : '生成失败: ';
  String get removePhoto => isEn ? 'Remove Photo' : '移除照片';

  // Default Form Inputs
  String get defaultDest => isEn ? 'Tokyo' : '东京';
  String get defaultDays => '3';
  String get defaultPrefs => isEn ? 'Love niche cafes, anime culture, slow pace.' : '喜欢小众咖啡馆、二次元、吃寿喜烧，节奏慢一点';

  // Weather & Generation Status Strings
  String get startDateLabel => isEn ? 'Start Date (Optional)' : '出发日期 (选填)';
  String get startDateHint => isEn ? 'Used for accurate weather forecast' : '填了才能让 AI 测算天气哦';
  String get selectDate => isEn ? 'Select Date' : '选择日期';
  String get statusFetchingWeather => isEn ? 'Connecting to weather satellites... 🌤️' : '正在连接气象卫星，获取当地天气... 🌤️';
  String get statusBadWeather => isEn ? 'Rain/Snow detected 🌧️\nAsking AI to switch outdoor activities to indoor...' : '发现未来几天有降水/恶劣天气 🌧️\n正在要求 AI 将户外活动智能替换为室内场馆...';
  String get statusGoodWeather => isEn ? 'Great weather ahead ☀️\nAI is crafting your perfect outdoor itinerary...' : '当地天气非常不错 ☀️\nAI 规划师正在为您生成完美路线...';
  String get statusDecoding => isEn ? 'Planning complete, decoding memory fragments... ✨' : '规划完成，正在解码记忆碎片... ✨';
  String get statusSkippingWeather => isEn ? 'Trip is too far in the future or no date selected.\nSkipping weather forecast, AI is planning... ✨' : '未选择近期出发日期，跳过天气预报，直接规划路线... ✨';

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
