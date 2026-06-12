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

    // 获取所有照片
    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (albums.isEmpty) return [];

    final AssetPathEntity recentAlbum = albums.first;
    // 取最近的 500 张照片进行扫描
    final List<AssetEntity> photos = await recentAlbum.getAssetListPaged(page: 0, size: 500);

    List<PhotoFootprint> footprints = [];
    final random = Random();

    // 提取行程所有 POI，为了时间推断，需要假定一个时间轴
    // 这里做简化处理：每个 POI 按顺序分配 2 小时
    List<_PoiWithTime> timeline = [];
    for (var day in itinerary.days) {
      DateTime dayStart = DateTime(day.date.year, day.date.month, day.date.day, 9, 0); // 每天早 9 点开始
      for (int i = 0; i < day.pois.length; i++) {
        timeline.add(_PoiWithTime(
          poi: day.pois[i],
          startTime: dayStart.add(Duration(hours: i * 2)),
          endTime: dayStart.add(Duration(hours: (i + 1) * 2)),
        ));
      }
    }

    for (var photo in photos) {
      final latlng = await photo.latlngAsync();
      POI? matchedPoi;

      if (latlng != null && latlng.latitude != 0 && latlng.longitude != 0) {
        // EXIF 匹配引擎：寻找距离最近且 < 0.5公里的 POI
        double minDistance = double.infinity;
        for (var t in timeline) {
          final dist = _calculateDistance(latlng.latitude, latlng.longitude, t.poi.location.latitude, t.poi.location.longitude);
          if (dist < minDistance && dist < 0.5) {
            minDistance = dist;
            matchedPoi = t.poi;
          }
        }
      }

      if (matchedPoi != null) {
        // 判断这个 POI 是否已经有匹配照片了，这里暂且一个 POI 只显示一张拍立得
        if (!footprints.any((f) => f.poi.id == matchedPoi!.id)) {
          final thumbnailData = await photo.thumbnailDataWithSize(const ThumbnailSize(200, 200));
          if (thumbnailData != null) {
            // 拍立得随机旋转角度 (-8 到 +8 度)
            final rotation = (random.nextDouble() - 0.5) * 16 * (pi / 180);
            footprints.add(PhotoFootprint(
              poi: matchedPoi,
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

class _PoiWithTime {
  final POI poi;
  final DateTime startTime;
  final DateTime endTime;
  _PoiWithTime({required this.poi, required this.startTime, required this.endTime});
}
