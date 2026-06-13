import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../domain/entities/itinerary.dart';

class ItineraryLocalDataSource {
  final SharedPreferences _prefs;
  static const String _storageKey = 'saved_itineraries';

  ItineraryLocalDataSource(this._prefs);

  /// 获取所有保存的行程
  List<Itinerary> getAllItineraries() {
    final String? jsonStr = _prefs.getString(_storageKey);
    if (jsonStr == null || jsonStr.isEmpty) {
      return [];
    }

    try {
      final List<dynamic> list = jsonDecode(jsonStr);
      return list.map((e) => Itinerary.fromJson(e)).toList();
    } catch (e) {
      return [];
    }
  }

  /// 保存单个行程
  Future<void> saveItinerary(Itinerary itinerary) async {
    final list = getAllItineraries();
    
    // 生成一个独特的 localId（如果还没有）
    final localId = itinerary.localId ?? DateTime.now().millisecondsSinceEpoch.toString();
    final updatedItinerary = itinerary.copyWith(localId: localId);

    // 检查是否已存在，存在则更新，不存在则添加
    final index = list.indexWhere((e) => e.localId == localId);
    if (index >= 0) {
      list[index] = updatedItinerary;
    } else {
      list.add(updatedItinerary);
    }

    await _saveList(list);
  }

  /// 删除单个行程
  Future<void> deleteItinerary(String localId) async {
    final list = getAllItineraries();
    list.removeWhere((e) => e.localId == localId);
    await _saveList(list);
  }

  /// 更新某个 POI 的照片列表（增量更新）
  Future<void> updatePoiPhotos(String localId, String poiId, List<String> newPhotoIds) async {
    final list = getAllItineraries();
    final tripIndex = list.indexWhere((e) => e.localId == localId);
    if (tripIndex < 0) return;

    final trip = list[tripIndex];
    final updatedDays = trip.days.map((day) {
      final updatedPois = day.pois.map((poi) {
        if (poi.id == poiId) {
          return poi.copyWith(photoIds: newPhotoIds);
        }
        return poi;
      }).toList();
      return day.copyWith(pois: updatedPois);
    }).toList();

    list[tripIndex] = trip.copyWith(days: updatedDays);
    await _saveList(list);
  }

  Future<void> _saveList(List<Itinerary> list) async {
    final String jsonStr = jsonEncode(list.map((e) => e.toJson()).toList());
    await _prefs.setString(_storageKey, jsonStr);
  }
}
