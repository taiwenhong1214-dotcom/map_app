import '../../domain/entities/itinerary.dart';
import '../../domain/repositories/i_ai_planner_repository.dart';
import '../datasources/ai_remote_datasource.dart';
import '../datasources/weather_datasource.dart';
import '../../core/coordinate/coordinate_converter.dart';
import 'package:flutter/material.dart';

class AiPlannerRepositoryImpl implements IAiPlannerRepository {
  final AiRemoteDataSource _dataSource;
  final WeatherDataSource _weatherDataSource = WeatherDataSource();

  AiPlannerRepositoryImpl(this._dataSource);

  @override
  Future<Itinerary> generateItinerary({
    required String destination,
    required int days,
    required String userPreferences,
  }) async {
    const systemPrompt = '''
你是一个专业的全球旅行AI规划师。请直接输出标准的JSON对象，不要有任何Markdown包裹。
你需要根据目的地、天数、天气预报和偏好生成行程安排。
重要：请根据【天气预报】进行智能穿搭解绑和室内外活动调度（例如：如果在下雨，请将户外活动替换为室内美术馆等，并在 POI 的 description 中体现因为天气的调整理由）。
必须包含每日的 POI（经纬度要求严格准确，WGS-84标准）。
JSON 格式要求：
{
  "title": "行程标题",
  "destination": "目的地",
  "days": [
    {
      "dayIndex": 1,
      "date": "2026-06-12",
      "pois": [
        {"id": "p1", "name": "景点名称", "lat": 39.9, "lng": 116.4, "description": "描述", "category": "attraction", "emoji": "🏛️"}
      ]
    }
  ]
}
''';

    // 先获取天气上下文
    final weatherContext = await _weatherDataSource.fetchWeatherForCity(destination, days);

    final prompt = "目的地: $destination, 天数: $days, 偏好: $userPreferences\n\n【当地天气预报】:\n$weatherContext";
    
    try {
      final jsonResult = await _dataSource.fetchAiCompletion(systemPrompt, prompt);
      return _parseItineraryFromJson(jsonResult);
    } catch (e) {
      debugPrint('⚠️ AI 规划网络请求失败，触发本地兜底生成机制: \$e');
      // 触发本地兜底机制 (针对国内 Vercel 访问不稳定的问题)
      return _generateMockItinerary(destination, days);
    }
  }

  @override
  Future<Itinerary> optimizeItineraryWithCopilot({
    required Itinerary currentItinerary,
    required String userPrompt,
  }) async {
    final currentContext = currentItinerary.days.map((day) {
      final poisStr = day.pois.map((p) => "\${p.name}(\${p.category ?? '未分类'})").join(', ');
      return '第\${day.dayIndex}天: $poisStr';
    }).join('\n');

    const systemPrompt = '''
你是一个高级旅行AI助手。用户会提供【当前行程】和【修改意见】。
请你根据意见修改行程，并直接输出完整的最新标准的JSON对象，不要有任何Markdown包裹。
JSON 格式严格要求与之前保持一致。
''';

    final prompt = """
【当前行程】:
$currentContext

【用户的修改指令】:
$userPrompt

请输出修改后的完整行程 JSON。
""";

    try {
      final jsonResult = await _dataSource.fetchAiCompletion(systemPrompt, prompt);
      return _parseItineraryFromJson(jsonResult);
    } catch (e) {
      debugPrint('⚠️ AI 伴游网络请求失败，触发本地修改兜底机制: \$e');
      // 模拟一点延迟，让用户感觉到 "AI 正在思考"
      await Future.delayed(const Duration(seconds: 1));
      
      // 拷贝当前行程，并对第一天的第一个景点加上 "✨(已根据你的要求调整)"
      final updatedDays = currentItinerary.days.map((day) {
        if (day.dayIndex == 1 && day.pois.isNotEmpty) {
          final firstPoi = day.pois.first;
          final updatedPoi = POI(
            id: firstPoi.id,
            name: '${firstPoi.name} ✨(已调整)',
            location: firstPoi.location,
            description: '$userPrompt -> 这是本地兜底触发的模拟修改结果。',
            category: firstPoi.category,
            emoji: firstPoi.emoji,
          );
          return ItineraryDay(
            dayIndex: day.dayIndex,
            date: day.date,
            pois: [updatedPoi, ...day.pois.skip(1)],
          );
        }
        return day;
      }).toList();

      return Itinerary(
        id: currentItinerary.id,
        title: currentItinerary.title,
        destination: currentItinerary.destination,
        days: updatedDays,
      );
    }
  }

  // 本地兜底生成逻辑
  Itinerary _generateMockItinerary(String destination, int days) {
    // 根据常见的城市，提供一个大致的坐标作为起点。如果是未知城市，默认在北京。
    LatLng84 center = const LatLng84(39.9042, 116.4074);
    if (destination.contains('东京') || destination.toLowerCase().contains('tokyo')) {
      center = const LatLng84(35.6895, 139.6917);
    } else if (destination.contains('大阪') || destination.toLowerCase().contains('osaka')) {
      center = const LatLng84(34.6937, 135.5023);
    } else if (destination.contains('上海') || destination.toLowerCase().contains('shanghai')) {
      center = const LatLng84(31.2304, 121.4737);
    } else if (destination.contains('巴黎') || destination.toLowerCase().contains('paris')) {
      center = const LatLng84(48.8566, 2.3522);
    }

    final mockDays = List.generate(days, (index) {
      return ItineraryDay(
        dayIndex: index + 1,
        date: DateTime.now().add(Duration(days: index)),
        pois: [
          POI(
            id: 'mock_${index}_1',
            name: '$destination 必去地 ${index * 2 + 1}',
            location: LatLng84(center.latitude + index * 0.01, center.longitude + index * 0.01),
            description: '这是由于网络连接失败，本地兜底引擎为你生成的景点。',
            category: 'Attraction',
            emoji: '📍',
          ),
          POI(
            id: 'mock_${index}_2',
            name: '$destination 特色餐厅 ${index * 2 + 2}',
            location: LatLng84(center.latitude + index * 0.012, center.longitude + index * 0.015),
            description: '这是本地兜底为你安排的就餐地点。',
            category: 'Restaurant',
            emoji: '🍽️',
          ),
        ],
      );
    });

    return Itinerary(
      id: 'mock_${DateTime.now().millisecondsSinceEpoch}',
      title: '[$destination] ${days}天探索之旅 (本地兜底)',
      destination: destination,
      days: mockDays,
    );
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
              id: poi['id'].toString(),
              name: poi['name'],
              // 注意：这里强制使用 WGS-84，契合架构设计
              location: LatLng84(poi['lat'].toDouble(), poi['lng'].toDouble()),
              description: poi['description'],
              category: poi['category'],
              emoji: poi['emoji'],
            );
          }).toList(),
        );
      }).toList(),
    );
  }
}