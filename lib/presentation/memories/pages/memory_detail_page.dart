import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/memory.dart';
import '../../../core/map_adapter/map_factory.dart';
import '../../../core/map_adapter/i_travel_map.dart';
import '../../planner/providers/planner_providers.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_provider.dart';
import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import '../../planner/widgets/photo_picker_sheet.dart';
import '../providers/memories_provider.dart';
import '../../../core/coordinate/coordinate_converter.dart';

class MemoryDetailPage extends ConsumerStatefulWidget {
  final MemoryAlbum album;

  const MemoryDetailPage({super.key, required this.album});

  @override
  ConsumerState<MemoryDetailPage> createState() => _MemoryDetailPageState();
}

class _MemoryDetailPageState extends ConsumerState<MemoryDetailPage> {
  ITravelMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    // 每次渲染都从 Provider 里拿最新的相册状态，防止自己拿旧的 widget.album
    final memoriesAsyncValue = ref.watch(memoriesProvider);
    final currentAlbum = memoriesAsyncValue.when(
      data: (albums) => albums.firstWhere(
        (a) => a.id == widget.album.id, 
        orElse: () => widget.album,
      ),
      loading: () => widget.album,
      error: (_, __) => widget.album,
    );

    final locale = ref.watch(localeProvider);
    final strings = context.strings(locale);

    final markers = currentAlbum.photos.map((photo) {
      return TravelMapMarker(
        id: photo.id,
        position: photo.location,
        onTap: () {
          _mapController?.moveCamera(photo.location, zoom: 16.0);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(photo.description ?? strings.viewedOnMap),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      );
    }).toList();

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
      body: Column(
        children: [
          // 上半部分：地图层
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.45,
            child: Stack(
              children: [
                // 地图底层
                Hero(
                  tag: 'album_cover_${widget.album.id}',
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
                    child: TravelMapFactory.build(
                      initialCenter: currentAlbum.centerLocation,
                      destinationForEngineDecision: currentAlbum.centerLocation,
                      initialZoom: 12.0,
                      markers: markers,
                      onMapCreated: (controller) {
                        _mapController = controller;
                      },
                    ),
                  ),
                ),
                // 顶部遮罩，保证返回按钮可见
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: 100,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                // 返回按钮
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  left: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                // 新增：上传照片按钮
                Positioned(
                  top: MediaQuery.of(context).padding.top + 8,
                  right: 16,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    child: IconButton(
                      icon: const Icon(Icons.add_a_photo, color: Colors.blueAccent),
                      onPressed: () async {
                        final usedIds = currentAlbum.photos.map((p) => p.id).toList();
                        final AssetEntity? asset = await showModalBottomSheet(
                          context: context,
                          backgroundColor: Colors.transparent,
                          builder: (ctx) => PhotoPickerSheet(alreadyUsedAssetIds: usedIds),
                        );
                        
                        if (asset != null) {
                          final file = await asset.file;
                          if (file != null) {
                            final latlng = await asset.latlngAsync();
                            final location = latlng != null && latlng.latitude != 0 
                                ? LatLng84(latlng.latitude, latlng.longitude) 
                                : currentAlbum.centerLocation; // Fallback

                            final newPhoto = MemoryPhoto(
                              id: asset.id,
                              imageUrl: file.path, // Use local file path
                              location: location,
                              timestamp: asset.createDateTime,
                              description: '刚刚上传的照片',
                            );
                            MemoriesActions.addPhotoToAlbum(currentAlbum.id, newPhoto);
                          }
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // 下半部分：信息与照片流
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              physics: const BouncingScrollPhysics(),
              children: [
                const SizedBox(height: 24),
                // 标题区
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentAlbum.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: isDark ? Colors.white54 : Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            strings.footprintsCount(currentAlbum.photos.length),
                            style: TextStyle(
                              fontSize: 15,
                              color: isDark ? Colors.white54 : Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // 照片网格
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.0, // 正方形照片
                  ),
                  itemCount: currentAlbum.photos.length,
                  itemBuilder: (context, index) {
                    final photo = currentAlbum.photos[index];
                    return GestureDetector(
                      onTap: () {
                        _mapController?.moveCamera(photo.location, zoom: 16.0);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            photo.imageUrl.startsWith('http')
                                ? Image.network(
                                    photo.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                                  )
                                : Image.file(
                                    File(photo.imageUrl),
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                                  ),
                            // 点击涟漪效果层
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  _mapController?.moveCamera(photo.location, zoom: 16.0);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}