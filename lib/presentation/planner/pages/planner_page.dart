import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/coordinate/coordinate_converter.dart';
import '../../../core/map_adapter/i_travel_map.dart';
import '../../../core/map_adapter/map_factory.dart';
import '../../../domain/entities/itinerary.dart';
import '../providers/planner_providers.dart';
import '../widgets/ai_copilot_fab.dart';
import '../widgets/ai_generation_form.dart';
import '../widgets/ai_copilot_chat_sheet.dart';
import '../../lbs_tracking/lbs_providers.dart';

// 把这里改成了 Stateful，为了保存地图控制器来随时移动镜头
class PlannerPage extends ConsumerStatefulWidget {
  const PlannerPage({super.key});

  @override
  ConsumerState<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends ConsumerState<PlannerPage> {
  // 保存地图控制器
  ITravelMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final itineraryState = ref.watch(currentItineraryNotifierProvider);
    final myLocState = ref.watch(locationProvider);

    // 🌟 核心升级：提前获取整个行程的路线和交通数据，供地图画线和列表时间展示共同使用
    Map<String, dynamic>? routeData;
    if (itineraryState.value != null) {
      final allPois = itineraryState.value!.days.expand((day) => day.pois).toList();
      if (allPois.length >= 2) {
        final coordsStr = allPois.map((p) => '${p.location.latitude},${p.location.longitude}').join('|');
        // 获取 OSRM 数据
        routeData = ref.watch(osrmRouteProvider(coordsStr)).valueOrNull;
      }
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. 底层：地图模块
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: itineraryState.value != null
                ? MediaQuery.of(context).size.height * 0.45
                : MediaQuery.of(context).size.height,
            child: _buildMapLayer(itineraryState.value, myLocState.value, routeData),
          ),

          // 2. 右上角：地图视角控制按钮组
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 16,
            child: Column(
              children: [
                // 回到我的位置按钮
                if (myLocState.value != null)
                  FloatingActionButton.small(
                    heroTag: 'btn_my_loc',
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: Colors.blueAccent),
                    onPressed: () {
                      // 点击平滑飞回自己的真实定位
                      _mapController?.moveCamera(myLocState.value!, zoom: 15.0);
                    },
                  ),
                const SizedBox(height: 12),
                // 回到目的地行程按钮
                if (itineraryState.value != null && itineraryState.value!.days.isNotEmpty)
                  FloatingActionButton.small(
                    heroTag: 'btn_dest',
                    backgroundColor: Colors.black87,
                    child: const Icon(Icons.map, color: Colors.white),
                    onPressed: () {
                      // 点击飞回行程目的地
                      final dest = itineraryState.value!.days.first.pois.first.location;
                      _mapController?.moveCamera(dest, zoom: 13.0);
                    },
                  ),
              ],
            ),
          ),

          // 3. 交互层：UI 面板
          SafeArea(
            child: itineraryState.when(
              data: (itinerary) {
                if (itinerary == null) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: AiGenerationForm(),
                    ),
                  );
                }
                return _buildItineraryPanel(context, itinerary, routeData);
              },
              loading: () => Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(16)),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.black87),
                      SizedBox(height: 16),
                      Text("AI 正在光速规划中...\n(可能需要 5-20 秒)", textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              error: (err, stack) => Center(
                child: Card(
                  color: Colors.red.shade50,
                  margin: const EdgeInsets.all(24),
                  child: Padding(padding: const EdgeInsets.all(16), child: Text('生成失败：$err', style: const TextStyle(color: Colors.red))),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: itineraryState.value != null
          ? AiCopilotFab(
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => const AiCopilotChatSheet(),
                );
              },
            )
          : null,
    );
  }

  /// 渲染地图与智能交通路线
  Widget _buildMapLayer(Itinerary? itinerary, LatLng84? myLoc, Map<String, dynamic>? routeData) {
    // 默认定位
    LatLng84 center = const LatLng84(39.9042, 116.4074);
    List<TravelMapMarker> markers = [];
    List<TravelMapPolyline> polylines = [];

    // 1. 设置定位图标
    if (myLoc != null) {
      center = myLoc;
      markers.add(TravelMapMarker(id: 'my_location', position: myLoc));
    }

    // 2. 设置目的地气球并把中心切到目的地
    List<LatLng84> routePoints = [];
    if (itinerary != null && itinerary.days.isNotEmpty) {
      final allPois = itinerary.days.expand((day) => day.pois).toList();
      if (allPois.isNotEmpty) {
        center = allPois.first.location; 
        routePoints = allPois.map((p) => p.location).toList();

        markers.addAll(allPois.map((poi) {
          return TravelMapMarker(id: poi.id, position: poi.location, label: poi.name);
        }));
      }
    }

    // 3. 渲染 OSRM 轨迹路线
    // 3. 渲染轨迹路线 (OSRM 真实马路优先，直线保底)
    if (routeData != null && routeData['points'] != null && (routeData['points'] as List).isNotEmpty) {
      // 🌟 OSRM 算路成功！画贴地马路
      final points = routeData['points'] as List<LatLng84>;
      polylines.add(TravelMapPolyline(
        id: 'osrm_road_route',
        points: points,
        color: const Color(0xFF4A90E2), // 深蓝色
        width: 5.0,
      ));
    } else {
      // 🌟 OSRM 还在加载中，或者发现这几个点开车到不了（算路失败）
      // 保底策略：把景点用浅蓝色虚线（直线）连起来，不至于让地图空着！
      if (routePoints.length >= 2) {
        polylines.add(TravelMapPolyline(
          id: 'straight_line_fallback',
          points: routePoints,
          color: Colors.blueAccent.withOpacity(0.4), // 浅蓝色半透明
          width: 3.0,
        ));
      }
    }

    // 修复了之前 fold 的类型报错，确保 UI 能够平滑更新
    final int poiCount = itinerary?.days.fold<int>(0, (int prev, day) => prev + day.pois.length) ?? 0;

    return TravelMapFactory.build(
      key: ValueKey('${itinerary?.id ?? 'default_map'}_${itinerary?.days.length ?? 0}_$poiCount'), 
      initialCenter: center,
      destinationForEngineDecision: center,
      initialZoom: 13.0,
      markers: markers,
      polylines: polylines,
      onMapCreated: (controller) {
        _mapController = controller; 
      },
    );
  }

  /// 渲染行程底部面板
  Widget _buildItineraryPanel(BuildContext context, Itinerary itinerary, Map<String, dynamic>? routeData) {
    int globalPoiIndex = 0; // 全局 POI 索引，用来映射 OSRM 返回的各段路线

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(margin: const EdgeInsets.only(top: 12, bottom: 16), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 24), child: Text(itinerary.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: itinerary.days.length,
                itemBuilder: (context, index) {
                  final day = itinerary.days[index];
                  // 渲染卡片并传入全局索引以提取交通数据
                  final card = _buildDayCard(day, globalPoiIndex, routeData);
                  globalPoiIndex += day.pois.length; // 更新下一个 day 的起点索引
                  return card;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 每天的行程卡片
  Widget _buildDayCard(ItineraryDay day, int startGlobalIndex, Map<String, dynamic>? routeData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: Colors.grey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('第 ${day.dayIndex} 天', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
            const SizedBox(height: 12),
            ...day.pois.asMap().entries.map((entry) {
              final index = entry.key;
              final poi = entry.value;

              // 🌟 核心升级：计算两点之间的真实交通耗时与距离！
              String trafficText = '智能交通计算中...';
              if (routeData != null && routeData['legs'] != null) {
                final legs = routeData['legs'] as List;
                final currentGlobalIndex = startGlobalIndex + index;
                // 防止越界
                if (currentGlobalIndex < legs.length) {
                  final leg = legs[currentGlobalIndex];
                  final distanceKm = (leg['distance'] / 1000).toStringAsFixed(1);
                  final durationMin = (leg['duration'] / 60).ceil();
                  trafficText = '🚗 驾车 $durationMin 分钟 ($distanceKm km)';
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.location_on, size: 20, color: Colors.black54),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(poi.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            if (poi.description != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, bottom: 12),
                                child: Text(poi.description!, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (index != day.pois.length - 1)
                    Container(
                      margin: const EdgeInsets.only(left: 9, bottom: 12),
                      padding: const EdgeInsets.only(left: 20),
                      decoration: const BoxDecoration(border: Border(left: BorderSide(color: Colors.blueAccent, width: 2, style: BorderStyle.solid))),
                      child: Row(
                        children: [
                          const Icon(Icons.directions_car, size: 16, color: Colors.blueAccent),
                          const SizedBox(width: 8),
                          // 🌟 在这里渲染真实的距离和耗时
                          Text(trafficText, style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}

extension AsyncValueX<T> on AsyncValue<T> {
  T? get valueOrNull => when(
        data: (d) => d,
        error: (e, s) => null,
        loading: () => null,
      );
}