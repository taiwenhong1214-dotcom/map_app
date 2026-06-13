import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'i_travel_map.dart';
import '../coordinate/coordinate_converter.dart';

/// 中国境内专属地图引擎：
/// 使用 flutter_map 驱动，底层加载高德地图瓦片，国内网络秒开。
/// 核心：在此层强制拦截所有 WGS-84 坐标，转换为 GCJ-02，完美贴合国内街道！
class ChinaMapWidget extends ITravelMap {
  const ChinaMapWidget({
    super.key,
    required super.initialCenter,
    super.initialZoom = 14.0,
    super.markers = const [],
    super.polylines = const [],
    super.onMapCreated,
  });

  @override
  State<ChinaMapWidget> createState() => _ChinaMapWidgetState();
}

class _ChinaMapWidgetState extends State<ChinaMapWidget> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onMapCreated?.call(_ChinaTravelMapController(_mapController));
    });
  }

  @override
  Widget build(BuildContext context) {
    // 🌟 核心转换 1：把初始视角的 WGS-84 转换成 GCJ-02
    final gcjCenter = CoordinateConverter.wgs84ToGcj02(widget.initialCenter);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: ll.LatLng(gcjCenter.latitude, gcjCenter.longitude),
        initialZoom: widget.initialZoom,
      ),
      children: [
        // 🌟 核心：白嫖高德地图的在线免费瓦片图层 (国内访问速度极快！)
        TileLayer(
          urlTemplate: 'https://webrd01.is.autonavi.com/appmaptile?lang=zh_cn&size=1&scale=1&style=8&x={x}&y={y}&z={z}',
          userAgentPackageName: 'com.example.map_app',
        ),
        
        // 渲染路线
        PolylineLayer(
          polylines: widget.polylines.map((p) {
            // 🌟 核心转换 2：把马路折线的每一个点，都转成火星坐标，贴合高德底图
            final gcjPoints = p.points.map((pt) {
              final gcj = CoordinateConverter.wgs84ToGcj02(pt);
              return ll.LatLng(gcj.latitude, gcj.longitude);
            }).toList();

            return Polyline(
              points: gcjPoints,
              color: p.color,
              strokeWidth: p.width,
            );
          }).toList(),
        ),
        
        // 渲染 Marker 气球
        MarkerLayer(
          markers: widget.markers.map((m) {
            // 🌟 核心转换 3：把景点的 WGS-84 坐标转成火星坐标
            final gcj = CoordinateConverter.wgs84ToGcj02(m.position);
            final isMyLocation = m.id == 'my_location';

            return Marker(
              point: ll.LatLng(gcj.latitude, gcj.longitude),
              width: 80.0,
              height: 80.0,
              alignment: Alignment.center,
              child: GestureDetector(
                onTap: m.onTap,
                child: isMyLocation
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.blueAccent,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3),
                          boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.5), blurRadius: 10)],
                        ),
                      )
                    : (m.imageBytes != null
                        ? Transform.rotate(
                            angle: m.rotation ?? 0,
                            child: Hero(
                              tag: 'memory_${m.id}',
                              child: Container(
                                padding: const EdgeInsets.fromLTRB(4, 4, 4, 16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(2),
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 6, offset: Offset(2, 4))],
                                ),
                                child: Image.memory(m.imageBytes!, fit: BoxFit.cover),
                              ),
                            ),
                          )
                        : (m.label != null
                            ? FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: m.id.startsWith('user_') ? Colors.green.shade700 : Colors.black87,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        m.label!, 
                                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    Icon(m.id.startsWith('user_') ? Icons.person_pin_circle : Icons.location_on, 
                                         color: m.id.startsWith('user_') ? Colors.green : Colors.redAccent, size: 36),
                                  ],
                                ),
                              )
                            : const Icon(Icons.location_on, color: Colors.redAccent, size: 40))),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// 控制器适配
class _ChinaTravelMapController implements ITravelMapController {
  final MapController _controller;
  _ChinaTravelMapController(this._controller);

  @override
  Future<void> moveCamera(LatLng84 target, {double? zoom}) async {
    // 平滑移动时，也需要转成 GCJ-02
    final gcj = CoordinateConverter.wgs84ToGcj02(target);
    _controller.move(ll.LatLng(gcj.latitude, gcj.longitude), zoom ?? 14.0);
  }

  @override
  Future<void> animateMarkerTo(String markerId, LatLng84 target, {Duration duration = const Duration(milliseconds: 800)}) async {}
  @override
  Future<void> highlightRegion(String geoJsonId, String geoJsonData, {Color fillColor = const Color(0x334A90E2)}) async {}
  @override
  void dispose() {}
}