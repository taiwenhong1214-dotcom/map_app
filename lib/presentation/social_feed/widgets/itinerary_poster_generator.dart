import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import '../../../domain/entities/itinerary.dart';
import '../../../data/repositories_impl/memory_repository_impl.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ItineraryPosterGenerator {
  static Future<void> sharePoster(WidgetRef ref, BuildContext context, Itinerary itinerary, List<PhotoFootprint> footprints) async {
    final screenshotController = ScreenshotController();
    
    final strings = context.strings(ref.read(localeProvider));
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.generatingPoster)));

    // 构建离屏的渲染 Widget（杂志风排版）
    final posterWidget = _buildPosterWidget(itinerary, footprints, strings);

    try {
      final imageBytes = await screenshotController.captureFromWidget(
        InheritedTheme.captureAll(
          context,
          Theme(
            data: ThemeData.light(),
            child: Material(child: posterWidget),
          ),
        ),
        delay: const Duration(milliseconds: 500),
        pixelRatio: 2.0, // 高清
      );

      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/travel_poster_${DateTime.now().millisecondsSinceEpoch}.png').create();
      await file.writeAsBytes(imageBytes);

      // 调起系统分享
      await Share.shareXFiles(
        [XFile(file.path)],
        text: strings.shareText(itinerary.destination),
      );
    } catch (e) {
      debugPrint('长图生成失败: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.generatePosterFailed)));
      }
    }
  }

  static Widget _buildPosterWidget(Itinerary itinerary, List<PhotoFootprint> footprints, AppStrings strings) {
    return Container(
      width: 400,
      color: Colors.grey.shade50,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Text(
                  itinerary.destination,
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
                ),
                const SizedBox(height: 8),
                Text(
                  itinerary.title,
                  style: const TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ],
            ),
          ),
          
          // Body (Days and POIs)
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: itinerary.days.map((day) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${strings.day} ${day.dayIndex}${strings.daySuffix}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.blueAccent)),
                      const SizedBox(height: 12),
                      ...day.pois.map((poi) {
                        // 查找是否有拍立得照片
                        final memory = footprints.where((f) => f.poi.id == poi.id).firstOrNull;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(poi.emoji ?? '📍', style: const TextStyle(fontSize: 24)),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(poi.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                    const SizedBox(height: 4),
                                    if (poi.description != null)
                                      Text(poi.description!, style: const TextStyle(color: Colors.black54, fontSize: 13)),
                                    
                                    // 渲染拍立得照片墙 (Magazine Style)
                                    if (memory != null)
                                      Container(
                                        margin: const EdgeInsets.only(top: 12),
                                        padding: const EdgeInsets.fromLTRB(6, 6, 6, 24),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))],
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Image.memory(memory.thumbnailData, fit: BoxFit.cover, height: 120, width: double.infinity),
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
                );
              }).toList(),
            ),
          ),

          // 🌟 杂志风留白页脚 (Magazine Footer)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            color: Colors.white,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        strings.posterQuote,
                        style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: Colors.black87, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Generated by Circular Travel',
                        style: TextStyle(fontSize: 12, color: Colors.black38, letterSpacing: 1),
                      ),
                    ],
                  ),
                ),
                // 极简二维码预留位
                Container(
                  width: 50,
                  height: 50,
                  color: Colors.black87,
                  alignment: Alignment.center,
                  child: const Icon(Icons.qr_code_2, color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
