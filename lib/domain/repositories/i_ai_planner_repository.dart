import '../entities/itinerary.dart';

/// AI 行程规划仓库接口
abstract class IAiPlannerRepository {
  /// 生成全新行程
  Future<Itinerary> generateItinerary({
    required String destination,
    required int days,
    required String userPreferences, // 如："休闲、美食为主"
  });

  /// 对话式路线优化（局部修改）
  Future<Itinerary> optimizeItineraryWithCopilot({
    required Itinerary currentItinerary,
    required String userPrompt, // 如："把下午的博物馆换成喝咖啡"
  });
}