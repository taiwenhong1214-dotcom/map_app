// lib/core/map_adapter/map_factory.dart

import 'package:flutter/material.dart';
import 'i_travel_map.dart';
import 'amap_widget.dart';
import 'google_map_widget.dart';
import '../coordinate/coordinate_converter.dart';

/// 地图工厂：根据目的地坐标判断使用国内/海外引擎
/// 这是「双引擎策略」的核心调度入口，整个 App 只能通过此工厂获取地图 Widget
class TravelMapFactory {
  TravelMapFactory._();

  /// 根据当前行程的目的地坐标，决定使用哪个地图引擎
  /// [destination] 行程目的地的 WGS-84 坐标，用于判断境内/境外
  /// [forceEngine] 可选：强制指定引擎（用于设置页手动切换）
  static MapEngineType resolveEngine(
    LatLng84 destination, {
    MapEngineType? forceEngine,
  }) {
    if (forceEngine != null) return forceEngine;

    // 复用坐标转换工具中的境内判断逻辑
    final gcj = CoordinateConverter.wgs84ToGcj02(destination);
    final isInChina = gcj.latitude != destination.latitude ||
        gcj.longitude != destination.longitude;

    return isInChina ? MapEngineType.amap : MapEngineType.google;
  }

  /// 创建对应引擎的地图 Widget
  static Widget build({
    required LatLng84 initialCenter,
    required LatLng84 destinationForEngineDecision,
    double initialZoom = 14.0,
    List<TravelMapMarker> markers = const [],
    List<TravelMapPolyline> polylines = const [],
    ValueChanged<ITravelMapController>? onMapCreated,
    MapEngineType? forceEngine,
  }) {
    final engine = resolveEngine(
      destinationForEngineDecision,
      forceEngine: forceEngine,
    );

    switch (engine) {
      case MapEngineType.amap:
        return AMapWidget(
          initialCenter: initialCenter,
          initialZoom: initialZoom,
          markers: markers,
          polylines: polylines,
          onMapCreated: onMapCreated,
        );
      case MapEngineType.google:
      case MapEngineType.mapbox:
        // Mapbox 作为 Google 的降级方案，接口签名一致
        return GoogleMapWidget(
          initialCenter: initialCenter,
          initialZoom: initialZoom,
          markers: markers,
          polylines: polylines,
          onMapCreated: onMapCreated,
        );
    }
  }
}