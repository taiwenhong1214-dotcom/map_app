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
    // 1. 将当前行程提取成简化的文本告诉大模型，作为上下文
    final currentContext = currentItinerary.days.map((day) {
      final pois = day.pois.map((p) => '${p.name}(${p.category ?? '未分类'})').join(', ');
      return '第${day.dayIndex}天: $pois';
    }).join('\n');

    // 2. 构造专属的系统提示词
    const systemPrompt = '''
你是一个高级旅行AI助手。用户会提供【当前行程】和【修改意见】。
请你根据意见修改行程，并直接输出完整的最新标准的JSON对象，不要有任何Markdown包裹。
JSON 格式严格要求与之前保持一致：
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

    // 3. 构造用户消息（包含上下文 + 新指令）
    final prompt = """
【当前行程】:
$currentContext

【用户的修改指令】:
$userPrompt

请输出修改后的完整行程 JSON。
""";

    // 4. 发送给 Vercel 接口
    final jsonResult = await _dataSource.fetchAiCompletion(systemPrompt, prompt);
    
    // 5. 解析并返回新行程
    return _parseItineraryFromJson(jsonResult);
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