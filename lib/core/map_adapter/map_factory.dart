import 'package:flutter/material.dart';
import 'i_travel_map.dart';
import 'osm_map_widget.dart';
import 'google_map_widget.dart';
import '../coordinate/coordinate_converter.dart';

/// 地图工厂：双引擎策略调度中心
class TravelMapFactory {
  TravelMapFactory._();

  /// 解析当前应使用的地图引擎
  static MapEngineType resolveEngine(
    LatLng84 destination, {
    MapEngineType? forceEngine,
  }) {
    // 1. 如果外部强行指定了引擎，优先使用
    if (forceEngine != null) return forceEngine;

    // 2. 根据目的地坐标判断境内外
    final gcj = CoordinateConverter.wgs84ToGcj02(destination);
    final isInChina = gcj.latitude != destination.latitude || 
                      gcj.longitude != destination.longitude;

    // 理想状态下：境内用 amap，境外用 google
    // 但由于目前移除了 amap 依赖，我们暂时全局返回 google
    // (等未来接回稳定版高德 SDK 时，把这里改回 isInChina ? MapEngineType.amap : MapEngineType.google 即可)
    return MapEngineType.google; 
  }

  /// 构建地图 Widget
  static Widget build({
    Key? key,
    required LatLng84 initialCenter,
    required LatLng84 destinationForEngineDecision,
    double initialZoom = 14.0,
    List<TravelMapMarker> markers = const [],
    List<TravelMapPolyline> polylines = const [],
    ValueChanged<ITravelMapController>? onMapCreated,
    MapEngineType? forceEngine,
  }) {
    final engine = resolveEngine(destinationForEngineDecision, forceEngine: forceEngine);

    // 根据决策结果分发 Widget
    switch (engine) {
      case MapEngineType.amap:
        // 优雅降级：原本该走高德的分支，暂时降级使用 Google Map
        // 并可以在控制台打印日志以便后续追踪
        debugPrint('⚠️ AMap is temporarily disabled. Falling back to Google Maps.');
        return GoogleMapWidget(
          key: key,
          initialCenter: initialCenter,
          initialZoom: initialZoom,
          markers: markers,
          polylines: polylines,
          onMapCreated: onMapCreated,
        );

      case MapEngineType.google:
      case MapEngineType.mapbox:
        return GoogleMapWidget(
          key: key,
          initialCenter: initialCenter,
          initialZoom: initialZoom,
          markers: markers,
          polylines: polylines,
          onMapCreated: onMapCreated,
        );
    }
  }
}