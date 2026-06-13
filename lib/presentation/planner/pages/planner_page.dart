import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:shimmer/shimmer.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../../core/coordinate/coordinate_converter.dart';
import '../../../core/map_adapter/i_travel_map.dart';
import '../../../core/map_adapter/map_factory.dart';
import '../../../domain/entities/itinerary.dart';
import '../providers/planner_providers.dart';
import '../widgets/ai_copilot_fab.dart';
import '../widgets/ai_generation_form.dart';
import '../widgets/map_search_bar.dart';
import '../widgets/my_trips_sheet.dart';
import '../widgets/ai_copilot_chat_sheet.dart';
import '../../lbs_tracking/lbs_providers.dart';
import '../../social_feed/widgets/publish_post_sheet.dart';
import '../../social_feed/widgets/itinerary_poster_generator.dart';
import '../widgets/photo_picker_sheet.dart';
import '../../../data/repositories_impl/memory_repository_impl.dart';
import '../../../core/i18n/locale_provider.dart';
import '../../../core/i18n/app_strings.dart';
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
    final footprints = ref.watch(photoFootprintsProvider);
    final locale = ref.watch(localeProvider);
    final strings = context.strings(locale);

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
            bottom: 0,
            child: _buildMapLayer(itineraryState.value, myLocState.value, routeData, footprints),
          ),

          // 🌟 2. 左上角：返回首页按钮 (仅在有行程时显示)
          if (itineraryState.value != null)
            Positioned(
              left: 0,
              top: MediaQuery.of(context).padding.top + 16,
              child: Material(
                color: Theme.of(context).cardColor,
                elevation: 0,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                child: InkWell(
                  borderRadius: const BorderRadius.only(
                    topRight: Radius.circular(24),
                    bottomRight: Radius.circular(24),
                  ),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    // 执行 Action: 清空数据，回到输入表单
                    ref.read(currentItineraryNotifierProvider.notifier).clear();
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(2, 0)),
                      ],
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(24),
                        bottomRight: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 20, 12),
                    child: Icon(Icons.home, color: Theme.of(context).iconTheme.color ?? Colors.black87, size: 22),
                  ),
                ),
              ),
            ),

          // 3. 右上角：地图视角与功能控制按钮组
          Positioned(
            right: 16,
            top: MediaQuery.of(context).padding.top + 16,
            child: Column(
              children: [
                // 🌟 新增：多语言切换按钮 (Task 3.4) - 仅在首页未加载时显示
                if (itineraryState.value == null && !itineraryState.isLoading) ...[
                  FloatingActionButton.small(
                    heroTag: 'btn_lang',
                    backgroundColor: Theme.of(context).colorScheme.surface,
                    child: Text(strings.isEn ? '中' : 'EN', style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold)),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.read(localeProvider.notifier).toggleLocale();
                    },
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.small(
                    heroTag: 'btn_my_trips',
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    child: const Icon(Icons.menu_book, color: Colors.white),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (ctx) => const MyTripsSheet(),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // 🌟 新增：刷新按钮 (用同样的参数让 AI 重新生成一份行程)
                if (itineraryState.value != null) ...[
                  FloatingActionButton.small(
                    heroTag: 'btn_refresh',
                    backgroundColor: Theme.of(context).cardColor,
                    elevation: 2,
                    child: Icon(Icons.refresh, color: Theme.of(context).colorScheme.primary),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      // 执行 Action: 重新生成
                      ref.read(currentItineraryNotifierProvider.notifier).refresh();
                    },
                  ),
                  const SizedBox(height: 12),
                ],

                // 回到目的地行程按钮
                if (itineraryState.value != null && itineraryState.value!.days.isNotEmpty) ...[
                  FloatingActionButton.small(
                    heroTag: 'btn_memory',
                    backgroundColor: Theme.of(context).cardColor,
                    elevation: 2,
                    child: const Icon(Icons.photo_album, color: Colors.pinkAccent),
                    onPressed: () async {
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.scanningMemories)));
                      final repo = ref.read(memoryRepositoryProvider);
                      final results = await repo.matchPhotosToItinerary(itineraryState.value!);
                      ref.read(photoFootprintsProvider.notifier).setFootprints(results);
                      if (results.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.noMemories)));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.memoriesLit.replaceAll('{0}', results.length.toString()))));
                      }
                    },
                  ),
                  const SizedBox(height: 12),
                  FloatingActionButton.small(
                    heroTag: 'btn_dest',
                    backgroundColor: Theme.of(context).cardColor,
                    elevation: 2,
                    child: Icon(Icons.map, color: Theme.of(context).iconTheme.color ?? Colors.black87),
                    onPressed: () {
                      HapticFeedback.lightImpact();
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
                    backgroundColor: Theme.of(context).cardColor,
                    elevation: 2,
                    child: Icon(Icons.my_location, color: Theme.of(context).colorScheme.primary),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _mapController?.moveCamera(myLocState.value!, zoom: 15.0);
                    },
                  ),
              ],
            ),
          ),

          // 新增：顶部悬浮搜索栏
          if (itineraryState.value == null) // 只在未生成行程（首页模式）时显示
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 70, // 避开左侧的 Home 按钮或返回按钮
              right: 70, // 避开右侧的语言切换和重新定位按钮
              child: MapSearchBar(
                onLocationFound: (latlng) {
                  _mapController?.moveCamera(latlng, zoom: 12.0);
                },
              ),
            ),

          // 4. 交互层：UI 面板
          SafeArea(
            child: itineraryState.when(
              data: (itinerary) {
                if (itinerary == null) {
                  return Align(
                    alignment: Alignment.bottomCenter,
                    child: AiGenerationForm(),
                  );
                }
                return _buildItineraryPanel(context, itinerary, routeData, strings);
              },
              loading: () => DraggableScrollableSheet(
                initialChildSize: 0.45,
                minChildSize: 0.1,
                maxChildSize: 0.85,
                builder: (context, scrollController) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, -4))],
                    ),
                    child: ListView(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        Center(
                          child: Container(
                            margin: const EdgeInsets.only(top: 8, bottom: 24),
                            width: 40,
                            height: 4,
                            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                          ),
                        ),
                        // Lottie 动画与轮播文案
                        Center(
                          child: ClipRect(
                            child: Lottie.network(
                              'https://assets2.lottiefiles.com/packages/lf20_yyjaunca.json', // 替换为更稳定的横向加载动画
                              height: 60,
                              width: double.infinity,
                              fit: BoxFit.fitHeight,
                              errorBuilder: (context, error, stackTrace) => const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: LinearProgressIndicator(color: Colors.blueAccent),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          strings.aiLoading, 
                          textAlign: TextAlign.center, 
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueAccent),
                        ),
                        const SizedBox(height: 32),
                        // 骨架屏列表
                        Shimmer.fromColors(
                          baseColor: Colors.grey.shade200,
                          highlightColor: Colors.grey.shade50,
                          child: Column(
                            children: List.generate(4, (index) => Padding(
                              padding: const EdgeInsets.only(bottom: 24),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12))),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Container(width: double.infinity, height: 18, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                                        const SizedBox(height: 8),
                                        Container(width: 150, height: 14, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(4))),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            )),
                          ),
                        ),
                      ],
                    ),
                  );
                },
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
  Widget _buildMapLayer(Itinerary? itinerary, LatLng84? myLoc, Map<String, dynamic>? routeData, List<PhotoFootprint> footprints) {
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

    // 🌟 处理拍立得照片足迹
    for (var f in footprints) {
      // 移除原本的红色 POI marker，替换为拍立得
      markers.removeWhere((m) => m.id == f.poi.id);
      markers.add(TravelMapMarker(
        id: f.poi.id,
        position: f.poi.location,
        label: f.poi.name,
        imageBytes: f.thumbnailData,
        rotation: f.randomRotation,
        onTap: () {
          HapticFeedback.lightImpact();
          showDialog(
            context: context,
            barrierColor: Colors.black87,
            builder: (ctx) => GestureDetector(
              onTap: () => Navigator.pop(ctx),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Hero(
                      tag: 'memory_${f.poi.id}',
                      child: Image.memory(f.thumbnailData, fit: BoxFit.contain),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        ref.read(photoFootprintsProvider.notifier).removeFootprint(f.poi.id);
                        Navigator.pop(ctx);
                        HapticFeedback.mediumImpact();
                      },
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('移除照片'),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ));
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
  Widget _buildItineraryPanel(BuildContext context, Itinerary itinerary, Map<String, dynamic>? routeData, AppStrings strings) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.1,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, -4))],
          ),
          // 整个区域都放进 ListView，这样拖拽顶部横条或标题也能上下拉
          child: ListView.builder(
            controller: scrollController,
            padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
            physics: const BouncingScrollPhysics(),
            itemCount: itinerary.days.length + 1, // +1 给 Header (横条+标题)
            itemBuilder: (context, index) {
              if (index == 0) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 拖拽把手
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 12, bottom: 16),
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                      ),
                    ),
                    // 标题与发布按钮
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(itinerary.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            child: Row(
                              children: [
                                if (itinerary.localId == null) ...[
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.orangeAccent,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                    ),
                                    icon: const Icon(Icons.save, size: 18),
                                    label: Text(strings.save, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    onPressed: () async {
                                      HapticFeedback.mediumImpact();
                                      await ref.read(currentItineraryNotifierProvider.notifier).saveToLocal();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(strings.savedToLocal)),
                                      );
                                    },
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blueAccent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  icon: const Icon(Icons.public, size: 18),
                                  label: Text(strings.publishCommunity, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (ctx) => PublishPostSheet(itinerary: itinerary),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  ),
                                  icon: const Icon(Icons.ios_share, size: 18),
                                  label: Text(strings.share, style: const TextStyle(fontWeight: FontWeight.bold)),
                                  onPressed: () {
                                    HapticFeedback.lightImpact();
                                    // Task 2.3 核心：一键生成杂志风长图
                                    final footprints = ref.read(photoFootprintsProvider);
                                    ItineraryPosterGenerator.sharePoster(context, itinerary, footprints, strings);
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              }

              // 具体行程卡片
              final dayIndex = index - 1;
              final day = itinerary.days[dayIndex];

              // 动态计算该天的全局起始索引（修复了之前基于状态自增导致滚动错乱的 bug）
              int startGlobalIndex = 0;
              for (int i = 0; i < dayIndex; i++) {
                startGlobalIndex += itinerary.days[i].pois.length;
              }

              final footprints = ref.watch(photoFootprintsProvider);
              return _buildDayCard(day, startGlobalIndex, routeData, footprints, strings);
            },
          ),
        );
      },
    );
  }

  /// 每天的行程卡片
  Widget _buildDayCard(ItineraryDay day, int startGlobalIndex, Map<String, dynamic>? routeData, List<PhotoFootprint> footprints, AppStrings strings) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.calendar_today, size: 18, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Text(
                  '${strings.day} ${day.dayIndex}${strings.daySuffix}',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...day.pois.asMap().entries.map((entry) {
              final index = entry.key;
              final poi = entry.value;

              // 🌟 UI 状态增强：只要 routeData 不为空，就说明算完了（不管是网络还是本地）！
              String trafficText = routeData == null ? strings.trafficLoading : strings.trafficLocal;

              if (routeData != null && routeData['legs'] != null) {
                final legs = routeData['legs'] as List;
                final currentGlobalIndex = startGlobalIndex + index;
                if (currentGlobalIndex < legs.length) {
                  final leg = legs[currentGlobalIndex];
                  final distanceKm = (leg['distance'] / 1000).toStringAsFixed(1);
                  final durationMin = (leg['duration'] / 60).ceil();
                  trafficText = strings.trafficInfo(durationMin, distanceKm);
                }
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 🌟 新增 Emoji 圆角卡片缩略图
                      Hero(
                        tag: 'emoji_${poi.id}',
                        child: Container(
                          width: 48,
                          height: 48,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.blue.withValues(alpha: 0.2) : Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? Colors.blue.withValues(alpha: 0.3) : Colors.blue.shade100, width: 1),
                          ),
                          child: Text(
                            poi.emoji ?? '📍',
                            style: const TextStyle(fontSize: 24),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [

                            Text(poi.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            if (poi.description != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4, bottom: 8),
                                child: Text(poi.description!, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54, fontSize: 13)),
                              ),
                            // 手动照片管理
                            Builder(
                              builder: (context) {
                                final footprint = footprints.where((f) => f.poi.id == poi.id).firstOrNull;
                                if (footprint != null) {
                                  return Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: Image.memory(footprint.thumbnailData, width: 24, height: 24, fit: BoxFit.cover),
                                      ),
                                      const SizedBox(width: 8),
                                      const Text('已添加足迹', style: TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.bold)),
                                    ],
                                  );
                                } else {
                                  return GestureDetector(
                                    onTap: () async {
                                      HapticFeedback.lightImpact();
                                      final usedIds = footprints.map((f) => f.asset.id).toList();
                                      final asset = await showModalBottomSheet(
                                        context: context,
                                        backgroundColor: Colors.transparent,
                                        builder: (ctx) => PhotoPickerSheet(alreadyUsedAssetIds: usedIds),
                                      );
                                      if (asset != null) {
                                        final repo = ref.read(memoryRepositoryProvider);
                                        final fp = await repo.createFootprintForPoi(poi, asset);
                                        if (fp != null) {
                                          ref.read(photoFootprintsProvider.notifier).addFootprint(fp);
                                          HapticFeedback.mediumImpact();
                                        }
                                      }
                                    },
                                    child: Row(
                                      children: [
                                        const Icon(Icons.add_a_photo, size: 14, color: Colors.blueAccent),
                                        const SizedBox(width: 4),
                                        Text(strings.addPhoto, style: const TextStyle(color: Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  );
                                }
                              },
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
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.directions_car,
                              size: 14, color: Theme.of(context).colorScheme.primary.withOpacity(0.8)),
                          const SizedBox(width: 8),
                          Text(trafficText,
                              style: TextStyle(
                                  color: Theme.of(context).colorScheme.primary.withOpacity(0.9),
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