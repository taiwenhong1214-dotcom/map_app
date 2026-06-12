// lib/core/map_adapter/google_map_widget.dart

import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart' as gmap;
import 'i_travel_map.dart';
import '../coordinate/coordinate_converter.dart';

/// Google 地图实现
/// 海外不存在坐标偏移问题，WGS-84 坐标直接透传给 SDK
class GoogleMapWidget extends ITravelMap {
  const GoogleMapWidget({
    super.key,
    required super.initialCenter,
    super.initialZoom = 14.0,
    super.markers = const [],
    super.polylines = const [],
    super.onMapCreated,
  });

  @override
  State<GoogleMapWidget> createState() => _GoogleMapWidgetState();
}

class _GoogleMapWidgetState extends State<GoogleMapWidget> {
  gmap.GoogleMapController? _controller;

  @override
  Widget build(BuildContext context) {
    return gmap.GoogleMap(
      initialCameraPosition: gmap.CameraPosition(
        target: gmap.LatLng(
          widget.initialCenter.latitude,
          widget.initialCenter.longitude,
        ),
        zoom: widget.initialZoom,
      ),
      markers: widget.markers.map((m) {
        return gmap.Marker(
          markerId: gmap.MarkerId(m.id),
          position: gmap.LatLng(m.position.latitude, m.position.longitude),
          onTap: m.onTap,
        );
      }).toSet(),
      polylines: widget.polylines.map((p) {
        return gmap.Polyline(
          polylineId: gmap.PolylineId(p.id),
          points: p.points
              .map((pt) => gmap.LatLng(pt.latitude, pt.longitude))
              .toList(),
          color: p.color,
          width: p.width.toInt(),
        );
      }).toSet(),
      onMapCreated: (controller) {
        _controller = controller;
        widget.onMapCreated?.call(_GoogleTravelMapController(controller));
      },
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
}

class _GoogleTravelMapController implements ITravelMapController {
  final gmap.GoogleMapController _controller;

  _GoogleTravelMapController(this._controller);

  @override
  Future<void> moveCamera(LatLng84 target, {double? zoom}) async {
    await _controller.animateCamera(
      gmap.CameraUpdate.newLatLngZoom(
        gmap.LatLng(target.latitude, target.longitude),
        zoom ?? 14.0,
      ),
    );
  }

  @override
  Future<void> animateMarkerTo(
    String markerId,
    LatLng84 target, {
    Duration duration = const Duration(milliseconds: 800),
  }) async {
    // TODO: Google Maps Flutter 不支持原生 marker 动画
    // 需通过 Timer 分帧更新 markers Set 中对应 marker 的 position 实现插值动画
  }

  @override
  Future<void> highlightRegion(
    String geoJsonId,
    String geoJsonData, {
    Color fillColor = const Color(0x334A90E2),
  }) async {
    // TODO: 解析 GeoJSON 为 gmap.Polygon 集合
  }

  @override
  void dispose() {}
}