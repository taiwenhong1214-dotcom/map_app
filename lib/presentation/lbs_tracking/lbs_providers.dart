// 文件路径：lib/presentation/lbs_tracking/providers/lbs_providers.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/coordinate/coordinate_converter.dart';

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
final osrmRouteProvider = FutureProvider.family<Map<String, dynamic>, String>((ref, coordsString) async {
  if (coordsString.isEmpty) return {'points': <LatLng84>[], 'legs': []};

  final parts = coordsString.split('|');
  if (parts.length < 2) return {'points': <LatLng84>[], 'legs': []};

  // OSRM 要求的格式是: lon,lat;lon,lat
  final osrmCoords = parts.map((p) {
    final latLng = p.split(',');
    return '${latLng[1]},${latLng[0]}'; // 注意: 经度在前, 纬度在后
  }).join(';');

  final url = 'https://router.project-osrm.org/route/v1/driving/$osrmCoords?geometries=geojson&overview=full';
  
  final dio = Dio();
  final res = await dio.get(url);
  final route = res.data['routes'][0];

  // 提取沿着马路走的弯曲坐标点
  final rawCoords = route['geometry']['coordinates'] as List;
  final polylinePoints = rawCoords.map((c) => LatLng84(c[1].toDouble(), c[0].toDouble())).toList();

  // 提取每两点之间的距离和耗时
  final legs = route['legs'] as List;
  final legInfos = legs.map((leg) => {
    'distance': leg['distance'], // 单位: 米
    'duration': leg['duration'], // 单位: 秒
  }).toList();

  return {
    'points': polylinePoints,
    'legs': legInfos,
  };
});