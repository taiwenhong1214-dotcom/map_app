import '../../core/coordinate/coordinate_converter.dart';

class MemoryPhoto {
  final String id;
  final String imageUrl;
  final LatLng84 location;
  final DateTime timestamp;
  final String? description;

  const MemoryPhoto({
    required this.id,
    required this.imageUrl,
    required this.location,
    required this.timestamp,
    this.description,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'imageUrl': imageUrl,
        'lat': location.latitude,
        'lng': location.longitude,
        'timestamp': timestamp.toIso8601String(),
        'description': description,
      };

  factory MemoryPhoto.fromJson(Map<String, dynamic> json) => MemoryPhoto(
        id: json['id'] as String,
        imageUrl: json['imageUrl'] as String,
        location: LatLng84(json['lat'] as double, json['lng'] as double),
        timestamp: DateTime.parse(json['timestamp'] as String),
        description: json['description'] as String?,
      );
}

class MemoryAlbum {
  final String id;
  final String title;
  final String coverImageUrl;
  final List<MemoryPhoto> photos;
  final LatLng84 centerLocation; // Used to center the map initially

  const MemoryAlbum({
    required this.id,
    required this.title,
    required this.coverImageUrl,
    required this.photos,
    required this.centerLocation,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'coverImageUrl': coverImageUrl,
        'lat': centerLocation.latitude,
        'lng': centerLocation.longitude,
        'photos': photos.map((p) => p.toJson()).toList(),
      };

  factory MemoryAlbum.fromJson(Map<String, dynamic> json) => MemoryAlbum(
        id: json['id'] as String,
        title: json['title'] as String,
        coverImageUrl: json['coverImageUrl'] as String,
        centerLocation: LatLng84(json['lat'] as double, json['lng'] as double),
        photos: (json['photos'] as List<dynamic>?)
                ?.map((e) => MemoryPhoto.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );
}