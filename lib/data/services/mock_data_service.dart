import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/social_post.dart';
import '../../domain/entities/memory.dart';
import '../../domain/entities/itinerary.dart';
import '../../core/coordinate/coordinate_converter.dart';

class MockDataService {
  static Future<void> seedIfEmpty() async {
    final firestore = FirebaseFirestore.instance;

    // Check if social posts are empty
    final socialQuery = await firestore.collection('social_posts').limit(1).get();
    if (socialQuery.docs.isEmpty) {
      final mockPosts = _getMockSocialPosts();
      for (var post in mockPosts) {
        final json = post.toJson();
        json.remove('id');
        await firestore.collection('social_posts').add(json);
      }
      print('Seeded mock social posts.');
    }

    // Check if memories are empty
    final memoriesQuery = await firestore.collection('memories').limit(1).get();
    if (memoriesQuery.docs.isEmpty) {
      final mockMemories = _getMockMemories();
      for (var album in mockMemories) {
        final json = album.toJson();
        json.remove('id');
        await firestore.collection('memories').add(json);
      }
      print('Seeded mock memory albums.');
    }
  }

  static List<SocialPost> _getMockSocialPosts() {
    return [
      SocialPost(
        id: '1',
        authorName: 'Alex Travels',
        authorAvatarUrl: 'https://i.pravatar.cc/150?img=11',
        title: '3 Days in Tokyo: Food & Culture',
        description: 'A perfect 3-day itinerary covering the best sushi, temples, and shopping in Tokyo. Highly recommended for first-timers!',
        coverImageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?q=80&w=800&auto=format&fit=crop',
        likesCount: 124,
        copyCount: 45,
        postedAt: DateTime.now().subtract(const Duration(hours: 2)),
        itinerary: Itinerary(
          id: 'it_tokyo_1',
          title: 'Tokyo 2 Days',
          destination: 'Tokyo',
          days: [
            ItineraryDay(
              dayIndex: 0,
              date: DateTime.now(),
              pois: [
                POI(
                  id: 'poi_1',
                  name: 'Senso-ji Temple',
                  location: LatLng84(35.7147, 139.7966),
                  category: 'Attraction',
                  emoji: '⛩️',
                ),
                POI(
                  id: 'poi_2',
                  name: 'Tsukiji Outer Market',
                  location: LatLng84(35.6654, 139.7706),
                  category: 'Food',
                  emoji: '🍣',
                ),
              ],
            ),
          ],
        ),
      ),
      SocialPost(
        id: '2',
        authorName: 'Sarah Explorer',
        authorAvatarUrl: 'https://i.pravatar.cc/150?img=5',
        title: 'Kyoto Hidden Gems',
        description: 'Escape the crowds and explore these quiet temples and local cafes in Kyoto.',
        coverImageUrl: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?q=80&w=800&auto=format&fit=crop',
        likesCount: 89,
        copyCount: 12,
        postedAt: DateTime.now().subtract(const Duration(days: 1)),
        itinerary: Itinerary(
          id: 'it_kyoto_1',
          title: 'Kyoto Hidden Gems',
          destination: 'Kyoto',
          days: [
            ItineraryDay(
              dayIndex: 0,
              date: DateTime.now(),
              pois: [
                POI(
                  id: 'poi_3',
                  name: 'Fushimi Inari Taisha',
                  location: LatLng84(34.9671, 135.7726),
                  category: 'Attraction',
                  emoji: '⛩️',
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  static List<MemoryAlbum> _getMockMemories() {
    return [
      MemoryAlbum(
        id: 'm1',
        title: 'Tokyo 2026',
        coverImageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?q=80&w=800&auto=format&fit=crop',
        centerLocation: LatLng84(35.6895, 139.6917),
        photos: [
          MemoryPhoto(
            id: 'p1',
            imageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?q=80&w=800&auto=format&fit=crop',
            location: LatLng84(35.6895, 139.6917),
            timestamp: DateTime.now().subtract(const Duration(days: 2)),
            description: 'Streets of Tokyo',
          ),
          MemoryPhoto(
            id: 'p2',
            imageUrl: 'https://images.unsplash.com/photo-1503899036084-c55cdd92da26?q=80&w=800&auto=format&fit=crop',
            location: LatLng84(35.7147, 139.7966),
            timestamp: DateTime.now().subtract(const Duration(days: 1)),
            description: 'Senso-ji',
          ),
        ],
      ),
      MemoryAlbum(
        id: 'm2',
        title: 'Kyoto Spring',
        coverImageUrl: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?q=80&w=800&auto=format&fit=crop',
        centerLocation: LatLng84(35.0116, 135.7680),
        photos: [
           MemoryPhoto(
            id: 'p3',
            imageUrl: 'https://images.unsplash.com/photo-1493976040374-85c8e12f0c0e?q=80&w=800&auto=format&fit=crop',
            location: LatLng84(34.9671, 135.7726),
            timestamp: DateTime.now().subtract(const Duration(days: 10)),
            description: 'Fushimi Inari',
          ),
        ],
      ),
    ];
  }
}
