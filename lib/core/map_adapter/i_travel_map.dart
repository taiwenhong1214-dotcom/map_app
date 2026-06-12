// lib/core/map_adapter/i_travel_map.dart

import 'package:flutter/material.dart';
import '../coordinate/coordinate_converter.dart';

/// 地图引擎类型
enum MapEngineType {
  amap,       // 高德地图（国内）
  google,     // Google Maps（海外，需 GMS 环境）
  mapbox,     // Mapbox（海外备选，无 GMS 环境兼容）
}

/// 地图标记数据模型（与具体 SDK 无关）
class TravelMapMarker {
  final String id;
  final LatLng84 position; // 永远是 WGS-84，由 Adapter 内部负责转换
  final String? label;
  final String? avatarUrl; // 用于好友头像标记
  final VoidCallback? onTap;

  const TravelMapMarker({
    required this.id,
    required this.position,
    this.label,
    this.avatarUrl,
    this.onTap,
  });
}

/// 地图路线（折线）模型
class TravelMapPolyline {
  final String id;
  final List<LatLng84> points;
  final Color color;
  final double width;

  const TravelMapPolyline({
    required this.id,
    required this.points,
    this.color = Colors.blue,
    this.width = 4.0,
  });
}

/// 统一地图控制器接口
/// Presentation 层通过此接口操作地图，不感知底层 SDK
abstract class ITravelMapController {
  /// 移动镜头到指定坐标（传入永远是 WGS-84）
  Future<void> moveCamera(LatLng84 target, {double? zoom});

  /// 平滑移动某个 marker（用于好友实时定位动画）
  Future<void> animateMarkerTo(String markerId, LatLng84 target,
      {Duration duration = const Duration(milliseconds: 800)});

  /// 高亮/点亮某个区域（足迹点亮功能，传入 GeoJSON 字符串）
  Future<void> highlightRegion(String geoJsonId, String geoJsonData,
      {Color fillColor});

  /// 释放资源
  void dispose();
}

/// 统一地图 Widget 抽象接口
/// UI 层只依赖此抽象，绝不直接 import 具体 SDK 的 Widget
abstract class ITravelMap extends StatefulWidget {
  final LatLng84 initialCenter;
  final double initialZoom;
  final List<TravelMapMarker> markers;
  final List<TravelMapPolyline> polylines;
  final ValueChanged<ITravelMapController>? onMapCreated;

  const ITravelMap({
    super.key,
    required this.initialCenter,
    this.initialZoom = 14.0,
    this.markers = const [],
    this.polylines = const [],
    this.onMapCreated,
  });
}