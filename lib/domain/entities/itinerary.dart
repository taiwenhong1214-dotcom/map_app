import '../../core/coordinate/coordinate_converter.dart';

/// 兴趣点 (Point of Interest)
class POI {
  final String id;
  final String name;
  final LatLng84 location;
  final String? description;
  final String? category; // 餐饮、景点、住宿等
  final String? emoji; // AI 智能配图（Emoji）

  const POI({
    required this.id,
    required this.name,
    required this.location,
    this.description,
    this.category,
    this.emoji,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'lat': location.latitude,
        'lng': location.longitude,
        'description': description,
        'category': category,
        'emoji': emoji,
      };

  factory POI.fromJson(Map<String, dynamic> json) => POI(
        id: json['id'],
        name: json['name'],
        location: LatLng84(json['lat'], json['lng']),
        description: json['description'],
        category: json['category'],
        emoji: json['emoji'],
      );
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

  Map<String, dynamic> toJson() => {
        'dayIndex': dayIndex,
        'date': date.toIso8601String(),
        'pois': pois.map((p) => p.toJson()).toList(),
      };

  factory ItineraryDay.fromJson(Map<String, dynamic> json) => ItineraryDay(
        dayIndex: json['dayIndex'],
        date: DateTime.parse(json['date']),
        pois: (json['pois'] as List).map((p) => POI.fromJson(p)).toList(),
      );
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

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'destination': destination,
        'days': days.map((d) => d.toJson()).toList(),
      };

  factory Itinerary.fromJson(Map<String, dynamic> json) => Itinerary(
        id: json['id'],
        title: json['title'],
        destination: json['destination'],
        days: (json['days'] as List).map((d) => ItineraryDay.fromJson(d)).toList(),
      );
}