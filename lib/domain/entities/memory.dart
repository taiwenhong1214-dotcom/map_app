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
}