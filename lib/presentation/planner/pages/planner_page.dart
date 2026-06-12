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
import '../../social_feed/widgets/publish_post_sheet.dart';

class PlannerPage extends ConsumerStatefulWidget {
  const PlannerPage({super.key});

  @override
  ConsumerState<PlannerPage> createState() => _PlannerPageState();
}

class _PlannerPageState extends ConsumerState<PlannerPage> {
  ITravelMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final itineraryState = ref.watch(currentItineraryNotifierProvider);
    final myLocState = ref.watch(locationProvider);

    Map<String, dynamic>? routeData;
    if (itineraryState.value != null) {
      final allPois = itineraryState.value!.days.expand((day) => day.pois).toList();
      if (allPois.length >= 2) {
        final coordsStr = allPois.map((p) => '${p.location.longitude},${p.location.latitude}').join('|');
        routeData = ref.watch(osrmRouteProvider(coordsStr)).value;
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

          // 🌟 2. 左上角：返回首页按钮 (仅在有行程时显示)
          if (itineraryState.value != null)
            Positioned(
              left: 16,
              top: MediaQuery.of(context).padding.top + 16,
              child: FloatingActionButton.small(
                heroTag: 'btn_home',
                backgroundColor: Colors.black87,
                elevation: 4,
                child: const Icon(Icons.home, color: Colors.white),
                onPressed: () {
                  // 执行 Action: 清空数据，回到输入表单
                  ref.read(currentItineraryNotifierProvider.notifier).clear();
                },
              ),
            ),

          // 3. 右上角：地图视角与功能控制按钮组
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 16,
            child: Column(
              children: [
                // 🌟 新增：刷新按钮 (用同样的参数让 AI 重新生成一份行程)
                if (itineraryState.value != null) ...[
                  FloatingActionButton.small(
                    heroTag: 'btn_refresh',
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.refresh, color: Colors.orange),
                    onPressed: () {
                      // 执行 Action: 重新生成
                      ref.read(currentItineraryNotifierProvider.notifier).refresh();
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // 回到目的地行程按钮
                if (itineraryState.value != null && itineraryState.value!.days.isNotEmpty) ...[
                  FloatingActionButton.small(
                    heroTag: 'btn_dest',
                    backgroundColor: Colors.black87,
                    child: const Icon(Icons.map, color: Colors.white),
                    onPressed: () {
                      final dest = itineraryState.value!.days.first.pois.first.location;
                      _mapController?.moveCamera(dest, zoom: 13.0);
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // 回到我的位置按钮
                if (myLocState.value != null)
                  FloatingActionButton.small(
                    heroTag: 'btn_my_loc',
                    backgroundColor: Colors.white,
                    child: const Icon(Icons.my_location, color: Colors.blueAccent),
                    onPressed: () {
                      _mapController?.moveCamera(myLocState.value!, zoom: 15.0);
                    },
                  ),
                const SizedBox(height: 12),

                // 🌟 新增：发布到社区按钮
                if (itineraryState.value != null && itineraryState.value!.days.isNotEmpty)
                  FloatingActionButton.extended(
                    heroTag: 'btn_publish',
                    backgroundColor: Colors.green,
                    icon: const Icon(Icons.public, color: Colors.white, size: 18),
                    label: const Text('发布行程', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => PublishPostSheet(itinerary: itineraryState.value!),
                      );
                    },
                  ),
              ],
            ),
          ),

          // 4. 交互层：UI 面板
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
    LatLng84 center = const LatLng84(39.9042, 116.4074);
    List<TravelMapMarker> markers = [];
    List<TravelMapPolyline> polylines = [];
    List<LatLng84> routePoints = [];

    if (myLoc != null) {
      center = myLoc;
      markers.add(TravelMapMarker(id: 'my_location', position: myLoc));
    }

    if (itinerary != null && itinerary.days.isNotEmpty) {
      final allPois = itinerary.days.expand((day) => day.pois).toList();
      if (allPois.isNotEmpty) {
        if (myLoc == null) center = allPois.first.location;
        routePoints.addAll(allPois.map((p) => p.location));

        markers.addAll(allPois.map((poi) {
          return TravelMapMarker(id: poi.id, position: poi.location, label: poi.name);
        }));
      }
    }

    if (routeData != null && routeData['points'] != null && (routeData['points'] as List<LatLng84>).isNotEmpty) {
      final List<LatLng84> points = routeData['points'];
      polylines.add(TravelMapPolyline(
        id: 'osrm_road_route',
        points: points,
        color: Colors.blueAccent,
        width: 5.0,
      ));
    } else {
      if (routePoints.length >= 2) {
        polylines.add(TravelMapPolyline(
          id: 'straight_line_fallback',
          points: routePoints,
          color: Colors.blueAccent.withOpacity(0.4),
          width: 3.0,
        ));
      }
    }

    final int poiCount = itinerary?.days.fold<int>(0, (int prev, day) => prev + day.pois.length) ?? 0;
    // 🌟 关键修复：将 routeData 的点数加入 Key，确保数据回来时地图 Widget 强制重绘
    final int routePointCount = (routeData?['points'] as List?)?.length ?? 0;
    final String routeKey = 'route_${routePointCount}_${routeData != null}';

    return TravelMapFactory.build(
      key: ValueKey('${itinerary?.id ?? 'default_map'}_${itinerary?.days.length ?? 0}_${poiCount}_$routeKey'), 
      initialCenter: itinerary != null && itinerary.days.isNotEmpty ? itinerary.days.first.pois.first.location : center,
      destinationForEngineDecision: itinerary != null && itinerary.days.isNotEmpty ? itinerary.days.first.pois.first.location : center,
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
    int globalPoiIndex = 0;

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
                  final card = _buildDayCard(day, globalPoiIndex, routeData);
                  globalPoiIndex += day.pois.length;
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
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 18, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Text(
                  '第 ${day.dayIndex} 天',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...day.pois.asMap().entries.map((entry) {
              final index = entry.key;
              final poi = entry.value;

              // 🌟 UI 状态增强：只要 routeData 不为空，就说明算完了（不管是网络还是本地）！
              String trafficText = routeData == null ? '⏳ 智能交通计算中...' : '📍 本地测算完成';

              if (routeData != null && routeData['legs'] != null) {
                final legs = routeData['legs'] as List;
                final currentGlobalIndex = startGlobalIndex + index;
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
                      margin: const EdgeInsets.only(left: 9, top: 4, bottom: 12),
                      padding: const EdgeInsets.only(left: 20),
                      decoration: BoxDecoration(
                        border: BorderDirectional(
                          start: BorderSide(
                            color: Colors.blueAccent.withOpacity(0.2),
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.directions_car,
                              size: 14, color: Colors.blueAccent.withOpacity(0.8)),
                          const SizedBox(width: 8),
                          Text(trafficText,
                              style: TextStyle(
                                  color: Colors.blueAccent.withOpacity(0.9),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500)),
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

// 移除错误的 extension，使用 AsyncValue 原生的 .value 即可