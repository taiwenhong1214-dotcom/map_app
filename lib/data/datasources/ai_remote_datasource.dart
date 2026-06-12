import 'package:dio/dio.dart';
import 'dart:convert';

/// AI 远程数据源：直接请求你的 Vercel 接口
class AiRemoteDataSource {
  final Dio dio;
  
  // ⚠️ 替换为你部署在 Vercel 上的真实域名
  // 例如：'https://tai-map-app.vercel.app/api/planner'
  static const String _vercelApiUrl = 'https://tai-map-app.vercel.app/api/planner';

  AiRemoteDataSource(this.dio) {
    dio.options.headers = {
      'Content-Type': 'application/json',
    };
  }

  Future<Map<String, dynamic>> fetchAiCompletion(String systemPrompt, String userMessage) async {
    try {
      // 直接向你的 Vercel 发送 POST 请求
      final response = await dio.post(
        _vercelApiUrl,
        data: {
          'systemPrompt': systemPrompt,
          'userMessage': userMessage,
        },
      );

      // 解析 Vercel 代理返回的数据
      // (这里假设你的 Vercel 接口直接返回了清洗好的 JSON 对象)
      if (response.data is String) {
         return json.decode(response.data);
      }
      return response.data;
      
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout || e.type == DioExceptionType.receiveTimeout) {
        throw Exception('网络超时啦！大模型思考时间过长或加速器网络不稳定，请重试。');
      }
      throw Exception('Vercel API 请求失败: ${e.response?.data ?? e.message}');
    } catch (e) {
      throw Exception('数据处理失败: $e');
    }
  }
}