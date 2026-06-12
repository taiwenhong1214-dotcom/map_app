// lib/core/coordinate/coordinate_converter.dart

import 'dart:math';

/// 坐标系类型标识
enum CoordinateSystem { wgs84, gcj02 }

/// 经纬度坐标值对象（Domain层统一使用此类型，永远代表 WGS-84）
class LatLng84 {
  final double latitude;
  final double longitude;

  const LatLng84(this.latitude, this.longitude);

  @override
  String toString() => 'LatLng84($latitude, $longitude)';
}

/// GCJ-02 坐标值对象（仅供 Presentation 层国内地图渲染使用）
class LatLngGcj02 {
  final double latitude;
  final double longitude;

  const LatLngGcj02(this.latitude, this.longitude);

  @override
  String toString() => 'LatLngGcj02($latitude, $longitude)';
}

/// WGS-84 <-> GCJ-02 转换工具
/// 算法来源：国测局官方加密算法的标准开源实现
class CoordinateConverter {
  CoordinateConverter._();

  static const double _a = 6378245.0;
  static const double _ee = 0.00669342162296594323;

  /// 判断坐标是否在中国境外（境外不做偏移，直接透传）
  static bool _outOfChina(double lat, double lng) {
    // 基本的粗略外接矩形
    if (lng < 72.004 || lng > 137.8347) return true;
    if (lat < 0.8293 || lat > 55.8271) return true;

    // 精细化排除日本、韩国等位于粗略边界内但不在中国的区域
    // 1. 纬度 < 39.0，经度 > 125.0 (涵盖冲绳、日本本土大部分、韩国，避开山东半岛)
    if (lat < 39.0 && lng > 125.0) return true;
    
    // 2. 纬度在 39.0 ~ 42.0 之间，经度 > 130.0 (涵盖日本北部、朝鲜东部，避开辽宁和吉林)
    if (lat >= 39.0 && lat < 42.0 && lng > 130.0) return true;
    
    // 3. 任何纬度，经度 > 135.0 (涵盖大阪以东、北海道、俄罗斯远东，避开黑龙江抚远)
    if (lng > 135.0) return true;

    // 4. 排除外蒙古等北方区域 (粗略排除 纬度 > 43.0 且 经度 < 115.0 的部分)
    // 比如乌兰巴托在 47.9N, 106.9E
    if (lat > 42.5 && lng < 115.0) return true;

    // 5. 排除东南亚部分区域 (缅甸、泰国、老挝、柬埔寨、越南南部)
    // 纬度 < 21.0，经度 < 106.0 (避开云南和广西南部)
    if (lat < 21.0 && lng < 106.0) return true;

    return false;
  }

  static double _transformLat(double x, double y) {
    double ret = -100.0 +
        2.0 * x +
        3.0 * y +
        0.2 * y * y +
        0.1 * x * y +
        0.2 * sqrt(x.abs());
    ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(y * pi) + 40.0 * sin(y / 3.0 * pi)) * 2.0 / 3.0;
    ret += (160.0 * sin(y / 12.0 * pi) + 320 * sin(y * pi / 30.0)) * 2.0 / 3.0;
    return ret;
  }

  static double _transformLng(double x, double y) {
    double ret = 300.0 +
        x +
        2.0 * y +
        0.1 * x * x +
        0.1 * x * y +
        0.1 * sqrt(x.abs());
    ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(x * pi) + 40.0 * sin(x / 3.0 * pi)) * 2.0 / 3.0;
    ret += (150.0 * sin(x / 12.0 * pi) + 300.0 * sin(x / 30.0 * pi)) * 2.0 / 3.0;
    return ret;
  }

  /// WGS-84 -> GCJ-02
  /// [forceConvert] 为 true 时跳过境外判断（极少数测试场景使用）
  static LatLngGcj02 wgs84ToGcj02(LatLng84 wgs, {bool forceConvert = false}) {
    final lat = wgs.latitude;
    final lng = wgs.longitude;

    if (!forceConvert && _outOfChina(lat, lng)) {
      // 境外坐标不偏移，直接透传
      return LatLngGcj02(lat, lng);
    }

    double dLat = _transformLat(lng - 105.0, lat - 35.0);
    double dLng = _transformLng(lng - 105.0, lat - 35.0);
    final radLat = lat / 180.0 * pi;
    double magic = sin(radLat);
    magic = 1 - _ee * magic * magic;
    final sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((_a * (1 - _ee)) / (magic * sqrtMagic) * pi);
    dLng = (dLng * 180.0) / (_a / sqrtMagic * cos(radLat) * pi);

    return LatLngGcj02(lat + dLat, lng + dLng);
  }

  /// GCJ-02 -> WGS-84
  /// 注意：此为迭代逆运算近似值，精度约 0.5 米，满足业务展示需求
  /// 不可用于高精度测绘场景
  static LatLng84 gcj02ToWgs84(LatLngGcj02 gcj) {
    final lat = gcj.latitude;
    final lng = gcj.longitude;

    if (_outOfChina(lat, lng)) {
      return LatLng84(lat, lng);
    }

    // 先用正向公式算出偏移量，再反向减去
    double dLat = _transformLat(lng - 105.0, lat - 35.0);
    double dLng = _transformLng(lng - 105.0, lat - 35.0);
    final radLat = lat / 180.0 * pi;
    double magic = sin(radLat);
    magic = 1 - _ee * magic * magic;
    final sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((_a * (1 - _ee)) / (magic * sqrtMagic) * pi);
    dLng = (dLng * 180.0) / (_a / sqrtMagic * cos(radLat) * pi);

    return LatLng84(lat - dLat, lng - dLng);
  }
}