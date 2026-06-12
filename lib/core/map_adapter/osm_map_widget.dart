import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'i_travel_map.dart';
import '../coordinate/coordinate_converter.dart';

class OsmMapWidget extends ITravelMap {
  const OsmMapWidget({
    super.key,
    required super.initialCenter,
    super.initialZoom = 14.0,
    super.markers = const [],
    super.polylines = const [],
    super.onMapCreated,
  });

  @override
  State<OsmMapWidget> createState() => _OsmMapWidgetState();
}

class _OsmMapWidgetState extends State<OsmMapWidget> {
  final MapController _mapController = MapController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.onMapCreated?.call(_OsmTravelMapController(_mapController));
    });
  }

  @override
  Widget build(BuildContext context) {
    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: ll.LatLng(widget.initialCenter.latitude, widget.initialCenter.longitude),
        initialZoom: widget.initialZoom,
      ),
      children: [
        // 免费的 OpenStreetMap 底图瓦片
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.map_app',
        ),
        // 渲染路线
        PolylineLayer(
          polylines: widget.polylines.map((p) {
            return Polyline(
              points: p.points.map((pt) => ll.LatLng(pt.latitude, pt.longitude)).toList(),
              color: p.color,
              strokeWidth: p.width,
            );
          }).toList(),
        ),
        // 渲染 Marker 气球
        // 渲染 Marker 气球和我的位置
        MarkerLayer(
          markers: widget.markers.map((m) {
            // 如果是“我的位置”，显示专属蓝色发光圆点，否则显示红色地标
            final isMyLocation = m.id == 'my_location';
            return Marker(
              point: ll.LatLng(m.position.latitude, m.position.longitude),
              width: isMyLocation ? 24 : 40,
              height: isMyLocation ? 24 : 40,
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
                    : const Icon(Icons.location_on, color: Colors.redAccent, size: 40),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

// 适配控制器
class _OsmTravelMapController implements ITravelMapController {
  final MapController _controller;
  _OsmTravelMapController(this._controller);

  @override
  Future<void> moveCamera(LatLng84 target, {double? zoom}) async {
    _controller.move(ll.LatLng(target.latitude, target.longitude), zoom ?? 14.0);
  }

  @override
  Future<void> animateMarkerTo(String markerId, LatLng84 target, {Duration duration = const Duration(milliseconds: 800)}) async {}
  @override
  Future<void> highlightRegion(String geoJsonId, String geoJsonData, {Color fillColor = const Color(0x334A90E2)}) async {}
  @override
  void dispose() {}
}