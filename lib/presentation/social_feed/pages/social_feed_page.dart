import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/social_feed_provider.dart';
import '../../../domain/entities/social_post.dart';
import '../../planner/providers/planner_providers.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_provider.dart';

class SocialFeedPage extends ConsumerWidget {
  const SocialFeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final posts = ref.watch(socialFeedProvider);
    final locale = ref.watch(localeProvider);
    final strings = context.strings(locale);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade100,
      appBar: AppBar(
        title: Text(strings.discoveryTitle, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0.5,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: posts.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final post = posts[index];
          return _buildPostCard(context, ref, post, isDark, strings);
        },
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, WidgetRef ref, SocialPost post, bool isDark, AppStrings strings) {
    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Avatar, Name, Time
          Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(post.authorAvatarUrl),
                radius: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    Text(
                      timeago.format(post.postedAt, locale: 'en_short'),
                      style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade600, fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_horiz),
                onPressed: () {},
                color: isDark ? Colors.white54 : Colors.grey.shade600,
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Content: Title & Description
          Text(
            post.title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            post.description,
            style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.grey.shade800, height: 1.4),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          
          // Image Cover
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Image.network(
                post.coverImageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
              ),
            ),
          ),
          const SizedBox(height: 12),
          
          // Itinerary snippet box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.map, color: Colors.blue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${post.itinerary.destination} · ${post.itinerary.days.length} ${strings.daysItinerary}',
                    style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Action: Copy to my planner
                    ref.read(socialFeedProvider.notifier).incrementCopy(post.id);
                    ref.read(currentItineraryNotifierProvider.notifier).setItinerary(post.itinerary);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(strings.itineraryCopied)),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text(strings.copyToPlanner),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Footer: Actions (Like, Share)
          Row(
            children: [
              _buildActionButton(
                icon: post.isLikedByMe ? Icons.favorite : Icons.favorite_border,
                color: post.isLikedByMe ? Colors.redAccent : Colors.grey.shade600,
                label: post.likesCount.toString(),
                onTap: () => ref.read(socialFeedProvider.notifier).toggleLike(post.id),
              ),
              const SizedBox(width: 24),
              _buildActionButton(
                icon: Icons.share_outlined,
                color: isDark ? Colors.white54 : Colors.grey.shade600,
                label: strings.share,
                onTap: () {},
              ),
              const Spacer(),
              Text(
                strings.copiesCount(post.copyCount),
                style: TextStyle(color: isDark ? Colors.white54 : Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required Color color, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}