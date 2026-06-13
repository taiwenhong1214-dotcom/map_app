import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../providers/social_feed_provider.dart';
import '../../../domain/entities/social_post.dart';
import '../../planner/providers/planner_providers.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_provider.dart';
import '../../../main.dart';
import 'dart:io';
import 'package:flutter/services.dart';

class SocialFeedPage extends ConsumerWidget {
  const SocialFeedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final postsAsyncValue = ref.watch(socialFeedProvider);
    final locale = ref.watch(localeProvider);
    final strings = context.strings(locale);

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(strings.discoveryTitle, style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        centerTitle: true,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
      ),
      body: postsAsyncValue.when(
        data: (posts) {
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.feed_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text('暂无社区动态', style: TextStyle(fontSize: 18, color: Colors.grey.shade500)),
                ],
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12),
            itemCount: posts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final post = posts[index];
              return _buildPostCard(context, ref, post, isDark, strings);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, st) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, WidgetRef ref, SocialPost post, bool isDark, AppStrings strings) {
    return Container(
      color: Theme.of(context).cardColor,
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
              if (post.authorId != null && post.authorId == ref.read(sharedPreferencesProvider).getString('device_id'))
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text('删除路线'),
                        content: Text('确定要删除你分享的这条路线吗？'),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('取消')),
                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text('删除', style: TextStyle(color: Colors.red))),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      SocialFeedActions.deletePost(post.id);
                    }
                  },
                  color: Colors.redAccent,
                )
              else
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
              child: post.coverImageUrl.startsWith('http')
                ? Image.network(
                    post.coverImageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
                  )
                : Image.file(
                    File(post.coverImageUrl),
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
              color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.2)),
            ),
            child: Row(
              children: [
                Icon(Icons.map, color: Theme.of(context).colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${post.itinerary.destination} · ${post.itinerary.days.length} ${strings.daysItinerary}',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w600),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Action: Copy to my planner
                    SocialFeedActions.incrementCopy(post.id);
                    ref.read(currentItineraryNotifierProvider.notifier).setItinerary(post.itinerary);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(strings.itineraryCopied)),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: Text(strings.copyToPlanner),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
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
                onTap: () {
                  SocialFeedActions.toggleLike(post.id, post.isLikedByMe);
                  HapticFeedback.lightImpact();
                },
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