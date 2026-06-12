import '../../core/coordinate/coordinate_converter.dart';

/// 兴趣点 (Point of Interest)
class POI {
  final String id;
  final String name;
  final LatLng84 location;
  final String? description;
  final String? category; // 餐饮、景点、住宿等

  const POI({
    required this.id,
    required this.name,
    required this.location,
    this.description,
    this.category,
  });
}

/// 每日行程安排
class ItineraryDay {
  final int dayIndex;
  final DateTime date;
  final List<POI> pois;

  const ItineraryDay({
    required this.dayIndex,
    required this.date,
    required this.pois,
  });
}

/// 行程聚合根
class Itinerary {
  final String id;
  final String title;
  final String destination;
  final List<ItineraryDay> days;

  const Itinerary({
    required this.id,
    required this.title,
    required this.destination,
    required this.days,
  });
}