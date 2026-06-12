import 'package:flutter/material.dart';
import '../../../domain/entities/memory.dart';
import '../../../core/map_adapter/map_factory.dart';
import '../../../core/map_adapter/i_travel_map.dart';

class MemoryDetailPage extends StatefulWidget {
  final MemoryAlbum album;

  const MemoryDetailPage({super.key, required this.album});

  @override
  State<MemoryDetailPage> createState() => _MemoryDetailPageState();
}

class _MemoryDetailPageState extends State<MemoryDetailPage> {
  ITravelMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final markers = widget.album.photos.map((photo) {
      return TravelMapMarker(
        id: photo.id,
        position: photo.location,
        onTap: () {
          _mapController?.moveCamera(photo.location, zoom: 16.0);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(photo.description ?? '在地图上查看了照片!'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        },
      );
    }).toList();

    return Scaffold(
      backgroundColor: Colors.white,
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
                      initialCenter: widget.album.centerLocation,
                      destinationForEngineDecision: widget.album.centerLocation,
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
                        widget.album.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.location_on, size: 16, color: Colors.grey.shade600),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.album.photos.length} 个足迹点',
                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.grey.shade600,
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
                  itemCount: widget.album.photos.length,
                  itemBuilder: (context, index) {
                    final photo = widget.album.photos[index];
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
                            Image.network(
                              photo.imageUrl,
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