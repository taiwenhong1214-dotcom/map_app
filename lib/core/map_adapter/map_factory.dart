import 'package:flutter/material.dart';
import 'i_travel_map.dart';
import 'osm_map_widget.dart';
import 'china_map_widget.dart';
import '../coordinate/coordinate_converter.dart';

class TravelMapFactory {
  TravelMapFactory._();

  static Widget build({
    Key? key,
    required LatLng84 initialCenter,
    required LatLng84 destinationForEngineDecision,
    double initialZoom = 14.0,
    List<TravelMapMarker> markers = const [],
    List<TravelMapPolyline> polylines = const [],
    ValueChanged<ITravelMapController>? onMapCreated,
  }) {
    // 🌟 智能决策：利用我们写好的转换器，判断目的地是否在中国境内
    final gcj = CoordinateConverter.wgs84ToGcj02(destinationForEngineDecision);
    final isInChina = gcj.latitude != destinationForEngineDecision.latitude || 
                      gcj.longitude != destinationForEngineDecision.longitude;

    if (isInChina) {
      // 🇨🇳 在国内：使用我们刚刚写的国内版地图（高德底图 + 火星坐标偏移修正）
      debugPrint("🌏 检测到中国坐标，自动切换为【高德火星坐标引擎】");
      return ChinaMapWidget(
        key: key,
        initialCenter: initialCenter,
        initialZoom: initialZoom,
        markers: markers,
        polylines: polylines,
        onMapCreated: onMapCreated,
      );
    } else {
      // 🌍 在海外：使用 OpenStreetMap 标准地球坐标系
      debugPrint("🌍 检测到海外坐标，自动切换为【OSM全球引擎】");
      return OsmMapWidget(
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