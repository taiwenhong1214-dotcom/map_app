import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class WeatherDataSource {
  final Dio _dio = Dio();

  Future<String> fetchWeatherForCity(String city, int days) async {
    try {
      // 1. Geocoding 查找经纬度
      final geoRes = await _dio.get('https://geocoding-api.open-meteo.com/v1/search', queryParameters: {
        'name': city,
        'count': 1,
        'language': 'zh',
        'format': 'json',
      });
      
      if (geoRes.data == null || geoRes.data['results'] == null || (geoRes.data['results'] as List).isEmpty) {
        return '未能获取到当地天气';
      }
      
      final location = geoRes.data['results'][0];
      final lat = location['latitude'];
      final lng = location['longitude'];

      // 2. 获取 Forecast (最多预测 16 天)
      final forecastDays = days > 16 ? 16 : (days < 1 ? 1 : days);
      final weatherRes = await _dio.get('https://api.open-meteo.com/v1/forecast', queryParameters: {
        'latitude': lat,
        'longitude': lng,
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
        'timezone': 'auto',
        'forecast_days': forecastDays,
      });

      if (weatherRes.data != null && weatherRes.data['daily'] != null) {
        final daily = weatherRes.data['daily'];
        final times = daily['time'] as List;
        final codes = daily['weather_code'] as List;
        final maxTemps = daily['temperature_2m_max'] as List;
        final minTemps = daily['temperature_2m_min'] as List;

        List<String> weatherList = [];
        for (int i = 0; i < times.length; i++) {
          final condition = _getWeatherCondition(codes[i]);
          weatherList.add('第${i+1}天(${times[i]}): $condition, 气温 ${minTemps[i]}°C~${maxTemps[i]}°C');
        }
        return weatherList.join('；\n');
      }
      return '未能获取到当地天气';
    } catch (e) {
      debugPrint('获取天气失败: $e');
      return '未能获取到当地天气';
    }
  }

  String _getWeatherCondition(int code) {
    if (code == 0) return '晴朗 ☀️';
    if (code == 1 || code == 2 || code == 3) return '多云 ⛅';
    if (code == 45 || code == 48) return '有雾 🌫️';
    if (code >= 51 && code <= 55) return '毛毛雨 🌧️';
    if (code >= 61 && code <= 65) return '下雨 🌧️';
    if (code >= 71 && code <= 75) return '下雪 ❄️';
    if (code >= 80 && code <= 82) return '阵雨 🌦️';
    if (code >= 95 && code <= 99) return '雷暴 ⛈️';
    return '阴天 ☁️';
  }
}
