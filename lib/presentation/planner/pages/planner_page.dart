import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../widgets/ai_copilot_chat_sheet.dart';
import '../../../core/coordinate/coordinate_converter.dart';
import '../../../core/map_adapter/i_travel_map.dart';
import '../../../core/map_adapter/map_factory.dart';
import '../../../domain/entities/itinerary.dart';
import '../providers/planner_providers.dart';
import '../widgets/ai_copilot_fab.dart';
import '../widgets/ai_generation_form.dart';

class PlannerPage extends ConsumerWidget {
  const PlannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 监听 AI 生成的行程状态
    final itineraryState = ref.watch(currentItineraryNotifierProvider);

    return Scaffold(
      body: Stack(
        children: [
          // 1. 底层：地图模块 (动态高度)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            // 如果有行程数据，地图占屏幕上方 40%；否则占满屏（作为背景）
            height: itineraryState.value != null
                ? MediaQuery.of(context).size.height * 0.45
                : MediaQuery.of(context).size.height,
            child: _buildMapLayer(itineraryState.value),
          ),

          // 2. 交互层：根据状态显示不同的 UI
          SafeArea(
            child: itineraryState.when(
              data: (itinerary) {
                if (itinerary == null) {
                  // 初始化状态：显示输入表单（居中）
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: AiGenerationForm(),
                    ),
                  );
                }
                // 生成成功：显示行程滑动面板
                return _buildItineraryPanel(context, itinerary);
              },
              loading: () => Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(color: Colors.black87),
                      SizedBox(height: 16),
                      Text("AI 正在光速规划中...\n(可能需要 5-10 秒)",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
              error: (err, stack) => Center(
                child: Card(
                  color: Colors.red.shade50,
                  margin: const EdgeInsets.all(24),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text('生成失败：$err', style: const TextStyle(color: Colors.red)),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: itineraryState.value != null
          ? AiCopilotFab(
              onTap: () {
                // 弹出聊天对话框
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true, // 允许弹窗被键盘顶起
                  backgroundColor: Colors.transparent,
                  builder: (context) => const AiCopilotChatSheet(),
                );
              },
            )
          : null,
    );
  }

  /// 渲染地图引擎，自动提取 POI 坐标转换为 Marker
  Widget _buildMapLayer(Itinerary? itinerary) {
    // 默认定位（若无行程则定位北京天安门，后续可替换为设备当前定位）
    LatLng84 center = const LatLng84(39.9042, 116.4074);
    List<TravelMapMarker> markers = [];
    List<TravelMapPolyline> polylines = [];

    if (itinerary != null && itinerary.days.isNotEmpty) {
      // 提取所有的 POI 渲染到地图上
      final allPois = itinerary.days.expand((day) => day.pois).toList();
      if (allPois.isNotEmpty) {
        center = allPois.first.location; // 将镜头移到第一个景点

        markers = allPois.map((poi) {
          return TravelMapMarker(
            id: poi.id,
            position: poi.location,
            label: poi.name,
            onTap: () {
              // 预留点击 Marker 高亮列表的联动功能
            },
          );
        }).toList();

        // 连线：将当天的 POI 连成轨迹
        polylines = itinerary.days.map((day) {
          return TravelMapPolyline(
            id: 'day_${day.dayIndex}',
            points: day.pois.map((p) => p.location).toList(),
            color: Colors.blueAccent.withOpacity(0.7),
            width: 4.0,
          );
        }).toList();
      }
    }

    // 严守双引擎策略约束，只能通过 Factory 构建
    return TravelMapFactory.build(
      key: ValueKey(itinerary?.id ?? 'default_map'), 
      initialCenter: center,
      destinationForEngineDecision: center, // 用于判断国内还是海外
      initialZoom: 12.0,
      markers: markers,
      polylines: polylines,
      onMapCreated: (controller) {
        // 可以将 controller 存入 ref 以便外部调用平移等操作
      },
    );
  }

  /// 渲染行程底部面板
  Widget _buildItineraryPanel(BuildContext context, Itinerary itinerary) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 顶部小横条 (拖拽提示)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            // 标题
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                itinerary.title,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 16),
            // 行程列表
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                physics: const BouncingScrollPhysics(),
                itemCount: itinerary.days.length,
                itemBuilder: (context, index) {
                  final day = itinerary.days[index];
                  return _buildDayCard(day);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 每天的行程卡片
  Widget _buildDayCard(ItineraryDay day) {
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
            Text(
              '第 ${day.dayIndex} 天',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
            ),
            const SizedBox(height: 12),
            ...day.pois.map((poi) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
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
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(poi.description!, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}