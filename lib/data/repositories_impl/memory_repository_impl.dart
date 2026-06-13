import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../domain/entities/itinerary.dart';
import '../../core/coordinate/coordinate_converter.dart';

class PhotoFootprint {
  final POI poi;
  final AssetEntity asset;
  final Uint8List thumbnailData;
  final double randomRotation;

  PhotoFootprint({
    required this.poi,
    required this.asset,
    required this.thumbnailData,
    required this.randomRotation,
  });
}

class MemoryRepositoryImpl {
  Future<List<PhotoFootprint>> matchPhotosToItinerary(Itinerary itinerary) async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.hasAccess) {
      debugPrint('相册权限被拒绝');
      return [];
    }

    if (itinerary.days.isEmpty) return [];

    // 获取行程的起止时间（放宽前后1天作为候选池）
    final DateTime startDate = itinerary.days.first.date.subtract(const Duration(days: 1));
    final DateTime endDate = itinerary.days.last.date.add(const Duration(days: 2)); // 加2天确保覆盖最后一天整天

    final filterOption = FilterOptionGroup(
      createTimeCond: DateTimeCond(
        min: startDate,
        max: endDate,
      ),
      orders: [
        const OrderOption(type: OrderOptionType.createDate, asc: false),
      ],
    );

    // 获取带有时间过滤的所有照片
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(
      type: RequestType.image,
      filterOption: filterOption,
    );
    if (albums.isEmpty) return [];

    final AssetPathEntity recentAlbum = albums.first;
    // 取出候选池里的照片（设定个上限比如5000张防爆内存）
    final List<AssetEntity> photos = await recentAlbum.getAssetListRange(start: 0, end: 5000);

    List<PhotoFootprint> footprints = [];
    final random = Random();

    // 提取行程所有 POI，作为匹配锚点
    List<POI> allPois = [];
    for (var day in itinerary.days) {
      allPois.addAll(day.pois);
    }

    for (var photo in photos) {
      final latlng = await photo.latlngAsync();

      // 规则 1：无 GPS 者直接淘汰 (No GPS, No Auto-Match)
      if (latlng == null || (latlng.latitude == 0 && latlng.longitude == 0)) {
        continue;
      }

      POI? nearestPoi;
      double minDistance = double.infinity;

      // 规则 2：最短距离贪心算法
      for (var poi in allPois) {
        final dist = _calculateDistance(
          latlng.latitude,
          latlng.longitude,
          poi.location.latitude,
          poi.location.longitude,
        );
        if (dist < minDistance) {
          minDistance = dist;
          nearestPoi = poi;
        }
      }

      // 判断 1000 米 (1.0 km) 阈值
      if (nearestPoi != null && minDistance <= 1.0) {
        // 判断这个 POI 是否已经有匹配照片了，这里暂且一个 POI 只显示一张拍立得
        if (!footprints.any((f) => f.poi.id == nearestPoi!.id)) {
          final thumbnailData = await photo.thumbnailDataWithSize(const ThumbnailSize(200, 200));
          if (thumbnailData != null) {
            // 拍立得随机旋转角度 (-8 到 +8 度)
            final rotation = (random.nextDouble() - 0.5) * 16 * (pi / 180);
            footprints.add(PhotoFootprint(
              poi: nearestPoi,
              asset: photo,
              thumbnailData: thumbnailData,
              randomRotation: rotation,
            ));
          }
        }
      }
    }

    return footprints;
  }

  Future<PhotoFootprint?> createFootprintForPoi(POI poi, AssetEntity asset) async {
    final thumbnailData = await asset.thumbnailDataWithSize(const ThumbnailSize(200, 200));
    if (thumbnailData == null) return null;

    final rotation = (Random().nextDouble() - 0.5) * 16 * (pi / 180);
    return PhotoFootprint(
      poi: poi,
      asset: asset,
      thumbnailData: thumbnailData,
      randomRotation: rotation,
    );
  }

  // Haversine 公式计算两点距离(公里)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    var p = 0.017453292519943295;
    var a = 0.5 - cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }
}


