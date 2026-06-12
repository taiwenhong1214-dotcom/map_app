import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/coordinate/coordinate_converter.dart';
import 'dart:math' as math;

// 1. 实时定位 Provider
final locationProvider = StreamProvider<LatLng84>((ref) async* {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) throw Exception('手机未开启定位服务');

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) throw Exception('定位权限被拒绝');
  }

  yield* Geolocator.getPositionStream(
    locationSettings: const LocationSettings(accuracy: LocationAccuracy.high, distanceFilter: 10),
  ).map((pos) => LatLng84(pos.latitude, pos.longitude));
});

// 🌟 极限安全的本地距离计算算法
double _calculateDistance(LatLng84 p1, LatLng84 p2) {
  try {
    const p = 0.017453292519943295;
    final a = 0.5 - math.cos((p2.latitude - p1.latitude) * p) / 2 +
        math.cos(p1.latitude * p) * math.cos(p2.latitude * p) *
        (1 - math.cos((p2.longitude - p1.longitude) * p)) / 2;
    // 使用 0.0 确保类型安全，防止微小负数导致的崩溃！
    return 12742 * math.asin(math.sqrt(math.max(0.0, a))) * 1000;
  } catch (e) {
    return 1000.0; // 就算陨石砸下来，也绝对不能崩溃，默认返回1公里
  }
}

// 2. OSRM 真实道路计算 Provider
final osrmRouteProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, coordsString) async {
  final emptyResult = {'points': <LatLng84>[], 'legs': []};
  if (coordsString.isEmpty) return emptyResult;

  final parts = coordsString.split('|');
  if (parts.length < 2) return emptyResult;

  // ===== 尝试网络请求 =====
  try {
    final osrmCoords = parts.map((p) {
      final latLng = p.split(',');
      return '${latLng[1]},${latLng[0]}';
    }).join(';');
    
    final url = 'https://router.project-osrm.org/route/v1/driving/$osrmCoords?geometries=geojson&overview=full';
    
    // 给 Dio 本身加上超时，双重保险
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(milliseconds: 2000),
      receiveTimeout: const Duration(milliseconds: 2000),
    ));

    final res = await dio.get(url);
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
  } catch (_) {
    // 静默拦截所有网络错误和超时，直接进入本地算法
  }
  
  // ===== 极限安全的本地兜底算法 =====
  try {
    List<Map<String, dynamic>> fallbackLegs = [];
    List<LatLng84> rawPoints = parts.map((p) {
      final latLng = p.split(',');
      return LatLng84(double.parse(latLng[0]), double.parse(latLng[1]));
    }).toList();

    for (int i = 0; i < rawPoints.length - 1; i++) {
      double straightDist = _calculateDistance(rawPoints[i], rawPoints[i+1]);
      double roadDist = straightDist * 1.4; // 1.4 倍曲折系数
      double durationSec = roadDist / 9.7;  // 按市区平均速度估算

      fallbackLegs.add({'distance': roadDist, 'duration': durationSec});
    }

    return {'points': rawPoints, 'legs': fallbackLegs};
  } catch (e) {
    return emptyResult; // 最坏情况：返回空数组，保底 UI 不卡死
  }
});