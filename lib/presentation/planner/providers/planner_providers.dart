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
import '../../../data/datasources/itinerary_local_datasource.dart';
import '../../../core/i18n/locale_provider.dart';
import '../../../core/i18n/app_strings.dart';

class GenerationStatusNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void setStatus(String? status) => state = status;
}

final generationStatusProvider = NotifierProvider<GenerationStatusNotifier, String?>(() {
  return GenerationStatusNotifier();
});

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

final itineraryLocalDataSourceProvider = Provider<ItineraryLocalDataSource>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ItineraryLocalDataSource(prefs);
});

// --- 状态管理 ---

// Search Bar Focus State (Deep Link)
class SearchFocusNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void triggerFocus() => state = true;
  void resetFocus() => state = false;
}
final searchFocusProvider = NotifierProvider<SearchFocusNotifier, bool>(() {
  return SearchFocusNotifier();
});

// Join Room Trigger State (Deep Link)
class JoinRoomTriggerNotifier extends Notifier<bool> {
  @override
  bool build() => false;
  void trigger() => state = true;
  void reset() => state = false;
}
final joinRoomTriggerProvider = NotifierProvider<JoinRoomTriggerNotifier, bool>(() {
  return JoinRoomTriggerNotifier();
});

// 1. 历史保存的行程
final savedTripsNotifierProvider = NotifierProvider<SavedTripsNotifier, List<Itinerary>>(() {
  return SavedTripsNotifier();
});

class SavedTripsNotifier extends Notifier<List<Itinerary>> {
  @override
  List<Itinerary> build() {
    return ref.watch(itineraryLocalDataSourceProvider).getAllItineraries();
  }

  Future<void> saveTrip(Itinerary trip) async {
    await ref.read(itineraryLocalDataSourceProvider).saveItinerary(trip);
    state = ref.read(itineraryLocalDataSourceProvider).getAllItineraries();
  }

  Future<void> deleteTrip(String localId) async {
    await ref.read(itineraryLocalDataSourceProvider).deleteItinerary(localId);
    state = ref.read(itineraryLocalDataSourceProvider).getAllItineraries();
  }
}

// 2. 照片足迹
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
    _syncPhotosToLocal(newFootprint.poi.id, [newFootprint.asset.id]);
  }

  void removeFootprint(String poiId) {
    state = state.where((f) => f.poi.id != poiId).toList();
    _syncPhotosToLocal(poiId, []);
  }

  void _syncPhotosToLocal(String poiId, List<String> newPhotoIds) {
    // 如果当前行程是本地保存的，则自动更新照片信息到本地
    final currentTrip = ref.read(currentItineraryNotifierProvider).value;
    if (currentTrip != null && currentTrip.localId != null) {
      ref.read(itineraryLocalDataSourceProvider).updatePoiPhotos(currentTrip.localId!, poiId, newPhotoIds);
      ref.read(savedTripsNotifierProvider.notifier).build(); // 刷新列表
    }
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
    // 🌟 杀后台重新打开时，不读取缓存，直接返回首页（输入表单）
    return null;
  }

  /// 一键生成全新行程
  Future<void> generate(String destination, int days, String preferences, {DateTime? startDate}) async {
    // 保存本次参数
    _lastDest = destination;
    _lastDays = days;
    _lastPrefs = preferences;

    state = const AsyncValue.loading();
    ref.read(photoFootprintsProvider.notifier).setFootprints([]);
    
    // Invalidate OSRM cache so we don't reuse straight-line fallbacks from previous failures
    // Note: since it's a family provider, we can't easily invalidate all instances without iterating,
    // but a hot restart will clear it anyway. To be safe, we'll let the user know to restart.
    try {
      final repo = ref.read(aiPlannerRepositoryProvider);
      
      final locale = ref.read(localeProvider);
      final strings = AppStrings(locale);
      final finalPrefs = '$preferences\n\n[SYSTEM INSTRUCTION: ${strings.aiLanguageInstruction}]';

      final itinerary = await repo.generateItinerary(
        destination: destination,
        days: days,
        userPreferences: finalPrefs,
        startDate: startDate,
        strings: strings,
        onStatusChanged: (status) {
          ref.read(generationStatusProvider.notifier).setStatus(status);
        },
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
    ref.read(photoFootprintsProvider.notifier).setFootprints([]);
    ref.read(sharedPreferencesProvider).remove('cached_itinerary');
  }

  /// 🌟 新增：直接设置行程（用于从社区一键复刻，或者从“我的行程”加载）
  void setItinerary(Itinerary itinerary) {
    state = AsyncValue.data(itinerary);
    ref.read(photoFootprintsProvider.notifier).setFootprints([]);
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString('cached_itinerary', jsonEncode(itinerary.toJson()));
  }

  /// 🌟 新增：将当前行程存入本地数据库
  Future<void> saveToLocal() async {
    final current = state.value;
    if (current == null) return;
    
    // 生成 localId 并保存
    final localId = current.localId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final updated = current.copyWith(localId: localId);
    
    await ref.read(savedTripsNotifierProvider.notifier).saveTrip(updated);
    
    // 更新当前状态为已保存状态
    state = AsyncValue.data(updated);
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setString('cached_itinerary', jsonEncode(updated.toJson()));
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