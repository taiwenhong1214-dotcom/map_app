import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/social_post.dart';
import '../../../domain/entities/itinerary.dart';
import '../../../core/coordinate/coordinate_converter.dart';

class SocialFeedNotifier extends Notifier<List<SocialPost>> {
  @override
  List<SocialPost> build() {
    // Mock data for the social feed
    return [
      SocialPost(
        id: 'post_1',
        authorName: 'Traveler Jane',
        authorAvatarUrl: 'https://i.pravatar.cc/150?img=1',
        title: '3 Days in Tokyo: Food & Culture',
        description: 'An amazing weekend exploring the bustling streets of Tokyo, eating sushi, and visiting historic shrines.',
        coverImageUrl: 'https://images.unsplash.com/photo-1540959733332-eab4deabeeaf?q=80&w=800&auto=format&fit=crop',
        likesCount: 124,
        copyCount: 45,
        postedAt: DateTime.now().subtract(const Duration(hours: 2)),
        itinerary: Itinerary(
          id: 'itin_tokyo_1',
          title: 'Tokyo Weekend Getaway',
          destination: 'Tokyo, Japan',
          days: [
            ItineraryDay(
              dayIndex: 1,
              date: DateTime.now(),
              pois: [
                const POI(id: 't1', name: 'Senso-ji Temple', location: LatLng84(35.7147, 139.7966), category: 'Attraction'),
                const POI(id: 't2', name: 'Tokyo Skytree', location: LatLng84(35.7100, 139.8107), category: 'Attraction'),
              ],
            ),
          ],
        ),
      ),
      SocialPost(
        id: 'post_2',
        authorName: 'Wanderlust Mike',
        authorAvatarUrl: 'https://i.pravatar.cc/150?img=11',
        title: 'Beijing Highlights',
        description: 'From the Forbidden City to the best Peking Duck in town. A must-do 2-day itinerary.',
        coverImageUrl: 'https://images.unsplash.com/photo-1608037521255-f7614e510860?q=80&w=800&auto=format&fit=crop',
        likesCount: 89,
        copyCount: 12,
        postedAt: DateTime.now().subtract(const Duration(days: 1)),
        itinerary: Itinerary(
          id: 'itin_bj_1',
          title: 'Classic Beijing',
          destination: 'Beijing, China',
          days: [
            ItineraryDay(
              dayIndex: 1,
              date: DateTime.now(),
              pois: [
                const POI(id: 'b1', name: 'Forbidden City', location: LatLng84(39.9163, 116.3971), category: 'Attraction'),
                const POI(id: 'b2', name: 'Temple of Heaven', location: LatLng84(39.8822, 116.4066), category: 'Attraction'),
              ],
            ),
          ],
        ),
      ),
    ];
  }

  void toggleLike(String postId) {
    state = state.map((post) {
      if (post.id == postId) {
        final newIsLiked = !post.isLikedByMe;
        return post.copyWith(
          isLikedByMe: newIsLiked,
          likesCount: post.likesCount + (newIsLiked ? 1 : -1),
        );
      }
      return post;
    }).toList();
  }

  void incrementCopy(String postId) {
    state = state.map((post) {
      if (post.id == postId) {
        return post.copyWith(copyCount: post.copyCount + 1);
      }
      return post;
    }).toList();
  }

  void addPost(SocialPost newPost) {
    // Add the new post to the top of the feed
    state = [newPost, ...state];
  }
}

final socialFeedProvider = NotifierProvider<SocialFeedNotifier, List<SocialPost>>(() {
  return SocialFeedNotifier();
});