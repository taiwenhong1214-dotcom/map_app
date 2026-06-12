import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/memory.dart';
import '../../../core/coordinate/coordinate_converter.dart';

class MemoriesNotifier extends Notifier<List<MemoryAlbum>> {
  @override
  List<MemoryAlbum> build() {
    // Return mock data for initial MVP state
    return [
      MemoryAlbum(
        id: 'album_1',
        title: 'Kyoto Autumn Trip',
        coverImageUrl: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?q=80&w=600&auto=format&fit=crop',
        centerLocation: const LatLng84(35.0116, 135.7681), // Kyoto
        photos: [
          MemoryPhoto(
            id: 'p1',
            imageUrl: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?q=80&w=400&auto=format&fit=crop',
            location: const LatLng84(34.9948, 135.7850), // Kiyomizu-dera
            timestamp: DateTime.now().subtract(const Duration(days: 10)),
            description: 'Beautiful autumn leaves.',
          ),
          MemoryPhoto(
            id: 'p2',
            imageUrl: 'https://images.unsplash.com/photo-1624253321171-1be53e12f5f4?q=80&w=400&auto=format&fit=crop',
            location: const LatLng84(35.0111, 135.6770), // Arashiyama
            timestamp: DateTime.now().subtract(const Duration(days: 9)),
            description: 'Bamboo forest walk.',
          ),
        ],
      ),
      MemoryAlbum(
        id: 'album_2',
        title: 'Shanghai City Walk',
        coverImageUrl: 'https://images.unsplash.com/photo-1548013146-72479768bada?q=80&w=600&auto=format&fit=crop',
        centerLocation: const LatLng84(31.2304, 121.4737), // Shanghai
        photos: [
          MemoryPhoto(
            id: 'p3',
            imageUrl: 'https://images.unsplash.com/photo-1548013146-72479768bada?q=80&w=400&auto=format&fit=crop',
            location: const LatLng84(31.2397, 121.4998), // The Bund
            timestamp: DateTime.now().subtract(const Duration(days: 30)),
            description: 'Night view of the Bund.',
          ),
        ],
      ),
    ];
  }
}

final memoriesProvider = NotifierProvider<MemoriesNotifier, List<MemoryAlbum>>(() {
  return MemoriesNotifier();
});