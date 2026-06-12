import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../data/datasources/ai_remote_datasource.dart';
import '../../../data/repositories_impl/ai_planner_repository_impl.dart';
import '../../../domain/repositories/i_ai_planner_repository.dart';
import '../../../domain/entities/itinerary.dart';

part 'planner_providers.g.dart'; // 运行 build_runner 生成

// --- 依赖注入 ---
@riverpod
Dio dio(Ref ref) => Dio();

@riverpod
AiRemoteDataSource aiRemoteDataSource(Ref ref) {
  return AiRemoteDataSource(ref.watch(dioProvider));
}

@riverpod
IAiPlannerRepository aiPlannerRepository(Ref ref) {
  return AiPlannerRepositoryImpl(ref.watch(aiRemoteDataSourceProvider));
}

// --- 状态管理 ---

/// 当前生成的行程状态
@riverpod
class CurrentItineraryNotifier extends _$CurrentItineraryNotifier {
  @override
  AsyncValue<Itinerary?> build() {
    return const AsyncValue.data(null);
  }

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
}