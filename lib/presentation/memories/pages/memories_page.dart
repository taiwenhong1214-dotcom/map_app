import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/memories_provider.dart';
import '../../planner/providers/planner_providers.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_provider.dart';
import 'memory_detail_page.dart';

class MemoriesPage extends ConsumerWidget {
  const MemoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albums = ref.watch(memoriesProvider);
    final locale = ref.watch(localeProvider);
    final strings = context.strings(locale);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : Colors.grey.shade50,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: Text(
              strings.navMemories,
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            backgroundColor: isDark ? const Color(0xFF121212) : Colors.white,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            floating: true,
          ),
          if (albums.isEmpty)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.photo_library_outlined, size: 80, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      strings.emptyMemories,
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      strings.startNewJourney,
                      style: TextStyle(color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final album = albums[index];
                    return GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            transitionDuration: const Duration(milliseconds: 500),
                            reverseTransitionDuration: const Duration(milliseconds: 500),
                            pageBuilder: (context, animation, secondaryAnimation) {
                              return FadeTransition(
                                opacity: animation,
                                child: MemoryDetailPage(album: album),
                              );
                            },
                          ),
                        );
                      },
                      child: Hero(
                        tag: 'album_cover_${album.id}',
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.network(
                                  album.coverImageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade300),
                                ),
                                // Gradient Overlay for text readability
                                Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topCenter,
                                      end: Alignment.bottomCenter,
                                      colors: [
                                        Colors.transparent,
                                        Colors.black.withValues(alpha: 0.0),
                                        Colors.black.withValues(alpha: 0.8),
                                      ],
                                      stops: const [0.0, 0.5, 1.0],
                                    ),
                                  ),
                                ),
                                Positioned(
                                  bottom: 16,
                                  left: 16,
                                  right: 16,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        album.title,
                                        style: TextStyle(
                                          color: isDark ? Colors.white : Colors.black87,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          height: 1.2,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.photo_library, size: 14, color: isDark ? Colors.white70 : Colors.black54),
                                          const SizedBox(width: 4),
                                          Text(
                                            strings.photosCount(album.photos.length),
                                            style: TextStyle(
                                              color: isDark ? Colors.white70 : Colors.black54,
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: albums.length,
                ),
              ),
            ),
          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}