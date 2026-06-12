import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../data/datasources/ai_remote_datasource.dart';
import '../../../data/repositories_impl/ai_planner_repository_impl.dart';
import '../../../domain/repositories/i_ai_planner_repository.dart';
import '../../../domain/entities/itinerary.dart';

// 注意：这里我们删掉了 part '...g.dart' 和 @riverpod 注解，完全手写！

// --- 依赖注入 ---
final dioProvider = Provider<Dio>((ref) {
  return Dio();
});

final aiRemoteDataSourceProvider = Provider<AiRemoteDataSource>((ref) {
  return AiRemoteDataSource(ref.watch(dioProvider));
});

final aiPlannerRepositoryProvider = Provider<IAiPlannerRepository>((ref) {
  return AiPlannerRepositoryImpl(ref.watch(aiRemoteDataSourceProvider));
});

// --- 状态管理 ---

// 手写定义 Provider
final currentItineraryNotifierProvider = 
    AsyncNotifierProvider<CurrentItineraryNotifier, Itinerary?>(() {
  return CurrentItineraryNotifier();
});

// 继承原生的 AsyncNotifier
class CurrentItineraryNotifier extends AsyncNotifier<Itinerary?> {
  @override
  FutureOr<Itinerary?> build() {
    return null; // 初始状态为空
  }

  /// 一键生成全新行程
  Future<void> generate(String destination, int days, String preferences) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(aiPlannerRepositoryProvider);
      final itinerary = await repo.generateItinerary(
        destination: destination,
        days: days,
        userPreferences: preferences,
      );
      state = AsyncValue.data(itinerary);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// 对话式微调当前行程 (Copilot)
  Future<void> modifyItinerary(String userPrompt) async {
    final currentItinerary = state.value;
    if (currentItinerary == null) return;

    state = const AsyncValue.loading();
    try {
      final repo = ref.read(aiPlannerRepositoryProvider);
      final newItinerary = await repo.optimizeItineraryWithCopilot(
        currentItinerary: currentItinerary,
        userPrompt: userPrompt,
      );
      state = AsyncValue.data(newItinerary);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}