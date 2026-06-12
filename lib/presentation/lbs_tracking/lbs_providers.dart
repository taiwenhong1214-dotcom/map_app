// 文件路径：lib/presentation/lbs_tracking/providers/lbs_providers.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/coordinate/coordinate_converter.dart';
import 'dart:math' as math;

// 1. 实时定位 Provider（获取真实经纬度）
final locationProvider = StreamProvider<LatLng84>((ref) async* {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) throw Exception('手机未开启定位服务');

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) throw Exception('定位权限被拒绝');
  }

  // 监听位置变化，每移动 10 米更新一次
  yield* Geolocator.getPositionStream(
    locationSettings: const LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 10,
    ),
  ).map((pos) => LatLng84(pos.latitude, pos.longitude));
});

// 2. OSRM 真实道路计算 Provider
// 传入坐标字符串（如 "lat,lng|lat,lng"），返回沿着马路的折线和交通耗时
// 🌟 辅助工具：本地计算两个坐标的直线距离 (单位：米)
double _calculateDistance(LatLng84 p1, LatLng84 p2) {
  const p = 0.017453292519943295; // Math.PI / 180
  final a = 0.5 - math.cos((p2.latitude - p1.latitude) * p) / 2 +
      math.cos(p1.latitude * p) * math.cos(p2.latitude * p) *
      (1 - math.cos((p2.longitude - p1.longitude) * p)) / 2;
  return 12742 * math.asin(math.sqrt(a)) * 1000;
}

// 2. OSRM 真实道路计算 Provider (自带极速本地兜底算法)
final osrmRouteProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, coordsString) async {
  final emptyResult = {'points': <LatLng84>[], 'legs': []};
  if (coordsString.isEmpty) return emptyResult;

  final parts = coordsString.split('|');
  if (parts.length < 2) return emptyResult;

  final osrmCoords = parts.map((p) {
    final latLng = p.split(',');
    return '${latLng[1]},${latLng[0]}';
  }).join(';');
  
  final url = 'https://router.project-osrm.org/route/v1/driving/$osrmCoords?geometries=geojson&overview=full';
  final dio = Dio();

  try {
    // 🌟 终极杀招：.timeout(2秒) 强制物理熔断！
    // 即使底层 DNS 卡死了，2秒一到也会强行抛出 TimeoutException 阻断它！
    final res = await dio.get(url).timeout(const Duration(seconds: 2));
    
    if (res.statusCode == 200 && res.data['routes'] != null && res.data['routes'].isNotEmpty) {
      final route = res.data['routes'][0];
      final rawCoords = route['geometry']['coordinates'] as List;
      final polylinePoints = rawCoords.map((c) => LatLng84(c[1].toDouble(), c[0].toDouble())).toList();

      final legs = route['legs'] as List;
      final legInfos = legs.map((leg) => {
        'distance': leg['distance'], 
        'duration': leg['duration'], 
      }).toList();

      return {'points': polylinePoints, 'legs': legInfos};
    }
  } catch (e) {
    // 捕获到 2 秒超时，立刻跳出，绝不让用户干等！
  }
  
  // ==========================================
  // 🌟 本地瞬间计算 (0毫秒延迟！)
  // ==========================================
  List<Map<String, dynamic>> fallbackLegs = [];
  List<LatLng84> rawPoints = parts.map((p) {
    final latLng = p.split(',');
    return LatLng84(double.parse(latLng[0]), double.parse(latLng[1]));
  }).toList();

  for (int i = 0; i < rawPoints.length - 1; i++) {
    // 算直线距离
    double straightDist = _calculateDistance(rawPoints[i], rawPoints[i+1]);
    // 乘以 1.4 的曲折系数，模拟真实城市道路长度
    double roadDist = straightDist * 1.4;
    // 假设城市平均车速 35km/h (约 9.7m/s)
    double durationSec = roadDist / 9.7; 

    fallbackLegs.add({
      'distance': roadDist,
      'duration': durationSec,
    });
  }

  // 瞬间返回计算数据！
  return {
    'points': <LatLng84>[], 
    'legs': fallbackLegs
  };
});