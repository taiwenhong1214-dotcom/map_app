import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../main.dart';

import '../../../data/datasources/ai_remote_datasource.dart';
import '../../../data/repositories_impl/ai_planner_repository_impl.dart';
import '../../../data/repositories_impl/memory_repository_impl.dart';
import '../../../domain/repositories/i_ai_planner_repository.dart';
import '../../../domain/entities/itinerary.dart';
import '../../../core/i18n/locale_provider.dart';
import '../../../core/i18n/app_strings.dart';

// 注意：这里我们删掉了 part '...g.dart' 和 @riverpod 注解，完全手写！

// --- 依赖注入 ---
final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      // 🌟 核心修复：把连接超时和接收超时时间拉长到 60 秒以上 (60000毫秒)
      // 防止在国内用加速器时，大模型思考太久导致前端主动断开连接
      connectTimeout: const Duration(milliseconds: 60000),
      receiveTimeout: const Duration(milliseconds: 90000), 
      sendTimeout: const Duration(milliseconds: 60000),
    ),
  );
  return dio;
});

final aiRemoteDataSourceProvider = Provider<AiRemoteDataSource>((ref) {
  return AiRemoteDataSource(ref.watch(dioProvider));
});

final aiPlannerRepositoryProvider = Provider<IAiPlannerRepository>((ref) {
  return AiPlannerRepositoryImpl(ref.watch(aiRemoteDataSourceProvider));
});

final memoryRepositoryProvider = Provider<MemoryRepositoryImpl>((ref) {
  return MemoryRepositoryImpl();
});

// --- 状态管理 ---

final photoFootprintsProvider = NotifierProvider<PhotoFootprintsNotifier, List<PhotoFootprint>>(() {
  return PhotoFootprintsNotifier();
});

class PhotoFootprintsNotifier extends Notifier<List<PhotoFootprint>> {
  @override
  List<PhotoFootprint> build() {
    return [];
  }

  void setFootprints(List<PhotoFootprint> newFootprints) {
    state = newFootprints;
  }

  void addFootprint(PhotoFootprint newFootprint) {
    // 移除同一 POI 的旧照片，加入新照片
    final List<PhotoFootprint> filtered = state.where((f) => f.poi.id != newFootprint.poi.id).toList();
    filtered.add(newFootprint);
    state = filtered;
  }

  void removeFootprint(String poiId) {
    state = state.where((f) => f.poi.id != poiId).toList();
  }
}

// 手写定义 Provider
final currentItineraryNotifierProvider = 
    AsyncNotifierProvider<CurrentItineraryNotifier, Itinerary?>(() {
  return CurrentItineraryNotifier();
});

// 继承原生的 AsyncNotifier
// 继承原生的 AsyncNotifier
class CurrentItineraryNotifier extends AsyncNotifier<Itinerary?> {
  // 🌟 缓存上一次的生成参数，供“刷新”按钮使用
  String? _lastDest;
  int? _lastDays;
  String? _lastPrefs;

  @override
  FutureOr<Itinerary?> build() {
    final prefs = ref.read(sharedPreferencesProvider);
    final cached = prefs.getString('cached_itinerary');
    if (cached != null) {
      try {
        final Map<String, dynamic> json = jsonDecode(cached);
        return Itinerary.fromJson(json);
      } catch (e) {
        // ignore parsing errors
      }
    }
    return null; // 初始状态为空
  }

  /// 一键生成全新行程
  Future<void> generate(String destination, int days, String preferences) async {
    // 保存本次参数
    _lastDest = destination;
    _lastDays = days;
    _lastPrefs = preferences;

    state = const AsyncValue.loading();
    try {
      final repo = ref.read(aiPlannerRepositoryProvider);
      
      final locale = ref.read(localeProvider);
      final strings = AppStrings(locale);
      final finalPrefs = '$preferences\n\n[SYSTEM INSTRUCTION: ${strings.aiLanguageInstruction}]';

      final itinerary = await repo.generateItinerary(
        destination: destination,
        days: days,
        userPreferences: finalPrefs,
      );

      // Task 3.1: 本地离线缓存
      final prefs = ref.read(sharedPreferencesProvider);
      prefs.setString('cached_itinerary', jsonEncode(itinerary.toJson()));

      state = AsyncValue.data(itinerary);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 🌟 新增：刷新（用上一次的参数重新生成一次）
  Future<void> refresh() async {
    if (_lastDest != null && _lastDays != null && _lastPrefs != null) {
      await generate(_lastDest!, _lastDays!, _lastPrefs!);
    }
  }

  /// 🌟 新增：返回首页（清空当前行程数据，回到输入表单）
  void clear() {
    state = const AsyncValue.data(null);
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.remove('cached_itinerary');
  }

  /// 🌟 新增：直接设置行程（用于从社区一键复刻）
  void setItinerary(Itinerary itinerary) {
    state = AsyncValue.data(itinerary);
  }

  /// 对话式微调当前行程 (Copilot)
  Future<void> modifyItinerary(String userPrompt) async {
    final currentItinerary = state.value;
    if (currentItinerary == null) return;

    state = const AsyncValue.loading();
    try {
      final repo = ref.read(aiPlannerRepositoryProvider);
      
      final locale = ref.read(localeProvider);
      final strings = AppStrings(locale);
      final finalPrompt = '$userPrompt\n\n[SYSTEM INSTRUCTION: ${strings.aiLanguageInstruction}]';

      final newItinerary = await repo.optimizeItineraryWithCopilot(
        currentItinerary: currentItinerary,
        userPrompt: finalPrompt,
      );
      state = AsyncValue.data(newItinerary);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}