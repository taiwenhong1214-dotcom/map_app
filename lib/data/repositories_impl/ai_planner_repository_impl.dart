import '../../domain/entities/itinerary.dart';
import '../../domain/repositories/i_ai_planner_repository.dart';
import '../datasources/ai_remote_datasource.dart';
import '../../core/coordinate/coordinate_converter.dart';

class AiPlannerRepositoryImpl implements IAiPlannerRepository {
  final AiRemoteDataSource _dataSource;

  AiPlannerRepositoryImpl(this._dataSource);

  @override
  Future<Itinerary> generateItinerary({
    required String destination,
    required int days,
    required String userPreferences,
  }) async {
    const systemPrompt = '''
你是一个专业的全球旅行AI规划师。请直接输出标准的JSON对象，不要有任何Markdown包裹。
你需要根据目的地、天数和偏好生成行程安排。必须包含每日的 POI（经纬度要求严格准确，WGS-84标准）。
JSON 格式要求：
{
  "title": "行程标题",
  "destination": "目的地",
  "days": [
    {
      "dayIndex": 1,
      "date": "2026-06-12",
      "pois": [
        {"id": "p1", "name": "景点名称", "lat": 39.9, "lng": 116.4, "description": "描述", "category": "attraction"}
      ]
    }
  ]
}
''';

    final prompt = "目的地: $destination, 天数: $days, 偏好: $userPreferences";
    
    final jsonResult = await _dataSource.fetchAiCompletion(systemPrompt, prompt);
    
    return _parseItineraryFromJson(jsonResult);
  }

  @override
  Future<Itinerary> optimizeItineraryWithCopilot({
    required Itinerary currentItinerary,
    required String userPrompt,
  }) async {
    // 逻辑类似，将 currentItinerary 序列化为 JSON 喂给 AI，并附带 userPrompt
    // ...
    throw UnimplementedError();
  }

  // 内部 DTO 转 Entity 工具
  Itinerary _parseItineraryFromJson(Map<String, dynamic> json) {
    return Itinerary(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: json['title'] ?? 'AI 生成行程',
      destination: json['destination'] ?? '',
      days: (json['days'] as List).map((day) {
        return ItineraryDay(
          dayIndex: day['dayIndex'],
          date: DateTime.parse(day['date']),
          pois: (day['pois'] as List).map((poi) {
            return POI(
              id: poi['id'],
              name: poi['name'],
              // 注意：这里强制使用 WGS-84，契合架构设计
              location: LatLng84(poi['lat'].toDouble(), poi['lng'].toDouble()),
              description: poi['description'],
              category: poi['category'],
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}