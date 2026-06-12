import 'dart:async';
import 'package:flutter/widgets.dart';
import '../coordinate/coordinate_converter.dart';

/// 坐标插值计算工具
class MapUtils {
  /// 线性插值计算两个经纬度之间的点
  static LatLng84 interpolate(LatLng84 start, LatLng84 end, double fraction) {
    final lat = start.latitude + (end.latitude - start.latitude) * fraction;
    final lng = start.longitude + (end.longitude - start.longitude) * fraction;
    return LatLng84(lat, lng);
  }
}

/// Marker 平滑移动动画执行器（脱离 Widget 生命周期，适用于 Controller）
class MarkerAnimator {
  Timer? _timer;

  /// 执行动画
  /// [start] 起点 WGS-84
  /// [end] 终点 WGS-84
  /// [duration] 动画时长
  /// [onUpdate] 每一帧的回调，回传当前插值坐标 (WGS-84)
  void animate({
    required LatLng84 start,
    required LatLng84 end,
    required Duration duration,
    required Function(LatLng84 currentPosition) onUpdate,
    VoidCallback? onComplete,
  }) {
    _timer?.cancel();
    
    const int fps = 60;
    final int totalFrames = (duration.inMilliseconds / (1000 / fps)).round();
    int currentFrame = 0;

    _timer = Timer.periodic(const Duration(milliseconds: 1000 ~/ fps), (timer) {
      currentFrame++;
      final fraction = currentFrame / totalFrames;
      
      // 曲线效果可以替换为 easeInOut，这里用简单线性插值
      final currentPos = MapUtils.interpolate(start, end, fraction);
      onUpdate(currentPos);

      if (currentFrame >= totalFrames) {
        timer.cancel();
        onUpdate(end); // 确保最后落在准确终点
        onComplete?.call();
      }
    });
  }

  void dispose() {
    _timer?.cancel();
  }
}