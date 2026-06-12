import 'dart:convert';
import 'package:flutter/material.dart';
import '../coordinate/coordinate_converter.dart';

class GeoJsonPolygon {
  final List<LatLng84> points;
  final Color fillColor;

  GeoJsonPolygon({required this.points, required this.fillColor});
}

class GeoJsonParser {
  /// 将 GeoJSON 字符串解析为业务层的 Polygon 模型集合
  /// 默认假定传入的 GeoJSON 坐标系为 WGS-84
  static List<GeoJsonPolygon> parse(String geoJsonString, Color defaultColor) {
    final List<GeoJsonPolygon> polygons = [];
    try {
      final Map<String, dynamic> data = json.decode(geoJsonString);
      final features = data['features'] as List?;
      if (features == null) return polygons;

      for (var feature in features) {
        final geometry = feature['geometry'];
        if (geometry != null && geometry['type'] == 'Polygon') {
          // 标准 GeoJSON 格式: coordinates[0] 是外环
          final coordinates = geometry['coordinates'][0] as List;
          final List<LatLng84> points = coordinates.map((coord) {
            return LatLng84(coord[1].toDouble(), coord[0].toDouble()); // [lng, lat] -> LatLng84(lat, lng)
          }).toList();
          
          polygons.add(GeoJsonPolygon(points: points, fillColor: defaultColor));
        }
      }
    } catch (e) {
      debugPrint("GeoJSON Parsing Error: $e");
    }
    return polygons;
  }
}