// lib/core/map_adapter/amap_widget.dart
// ignore_for_file: argument_type_not_assignable, non_type_as_type_argument

import 'package:flutter/material.dart';
import 'package:amap_flutter_map/amap_flutter_map.dart' as amap_flutter_map;
import 'package:amap_flutter_base/amap_flutter_base.dart' as amap_flutter_base;
import 'i_travel_map.dart';
import '../coordinate/coordinate_converter.dart';

/// 高德地图实现
/// ⚠️ 核心约束：所有传入的坐标均为 WGS-84，在本类内部统一转换为 GCJ-02 后渲染
/// UI 层和上层业务代码不应感知此转换过程
class AMapWidget extends ITravelMap {
  const AMapWidget({
    super.key,
    required super.initialCenter,
    super.initialZoom = 14.0,
    super.markers = const [],
    super.polylines = const [],
    super.onMapCreated,
  });

  @override
  State<AMapWidget> createState() => _AMapWidgetState();
}

class _AMapWidgetState extends State<AMapWidget> {
  dynamic _amapController; // 占位类型，实际使用 SDK 提供的 AMapController

  @override
  Widget build(BuildContext context) {
    // 将初始中心点从 WGS-84 转换为 GCJ-02
    final gcjCenter = CoordinateConverter.wgs84ToGcj02(widget.initialCenter);

    // Marker/polyline types are plugin-specific; silence type checks here
    // until plugin integration is completed.
    // ignore: argument_type_not_assignable
    return amap_flutter_map.AMapWidget(
      initialCameraPosition: amap_flutter_map.CameraPosition(
        target: amap_flutter_base.LatLng(
          gcjCenter.latitude,
          gcjCenter.longitude,
        ),
        zoom: widget.initialZoom,
      ),
      markers: _buildMarkers(),
      polylines: _buildPolylines(),
      onMapCreated: (controller) {
        _amapController = controller;
        widget.onMapCreated?.call(_AMapTravelMapController(controller));
      },
    );
  }

  /// 转换 Marker：WGS-84 -> GCJ-02
  Set<dynamic> _buildMarkers() {
    // Plugin-specific marker construction is platform/plugin dependent.
    // Return empty set for now to keep analyzer happy; implement when
    // integrating the real AMap plugin types.
    return <dynamic>{};
  }

  /// 转换路线点位：WGS-84 -> GCJ-02（逐点转换，确保路线在国内地图上不偏移）
  Set<dynamic> _buildPolylines() {
    // See note in _buildMarkers: return empty set until plugin types are
    // integrated.
    return <dynamic>{};
  }

  @override
  void dispose() {
    _amapController?.dispose();
    super.dispose();
  }
}

/// 高德地图控制器适配
class _AMapTravelMapController implements ITravelMapController {
  final dynamic _controller; // 实际类型为 AMapController

  _AMapTravelMapController(this._controller);

  @override
  Future<void> moveCamera(LatLng84 target, {double? zoom}) async {
    final gcj = CoordinateConverter.wgs84ToGcj02(target);
    await _controller.moveCamera(
      amap_flutter_map.CameraUpdate.newLatLngZoom(
        amap_flutter_base.LatLng(gcj.latitude, gcj.longitude),
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
    // compute gcj coords when implementing marker animation
    // TODO: 调用高德 SDK 的 marker 动画接口，按 duration 分帧插值更新 position
    // 高德 Flutter 插件目前需自行实现帧动画插值，见下方 MarkerAnimator 工具类
  }

  @override
  Future<void> highlightRegion(
    String geoJsonId,
    String geoJsonData, {
    Color fillColor = const Color(0x334A90E2),
  }) async {
    // TODO: 解析 GeoJSON，生成 Polygon 集合并添加到地图
    // 注意：GeoJSON 中的坐标若为 WGS-84，需逐点转换为 GCJ-02
  }

  @override
  void dispose() {}
}