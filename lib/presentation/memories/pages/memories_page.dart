import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/memories_provider.dart';
import '../../planner/providers/planner_providers.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../planner/widgets/photo_picker_sheet.dart';
import '../../../domain/entities/memory.dart';
import '../../../core/coordinate/coordinate_converter.dart';
import 'memory_detail_page.dart';

class MemoriesPage extends ConsumerWidget {
  const MemoriesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final albumsAsyncValue = ref.watch(memoriesProvider);
    final locale = ref.watch(localeProvider);
    final strings = context.strings(locale);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar.large(
            title: Text(
              strings.navMemories,
              style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2),
            ),
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            floating: true,
          ),
          albumsAsyncValue.when(
            data: (albums) {
              if (albums.isEmpty) {
                return SliverFillRemaining(
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
                );
              }
              return SliverPadding(
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
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 16,
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
                                          style: const TextStyle(
                                            color: Colors.white,
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
                                            const Icon(Icons.photo_library, size: 14, color: Colors.white70),
                                            const SizedBox(width: 4),
                                            Text(
                                              strings.photosCount(album.photos.length),
                                              style: const TextStyle(
                                                color: Colors.white70,
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
              );
            },
            loading: () => const SliverFillRemaining(child: Center(child: CircularProgressIndicator())),
            error: (e, st) => SliverFillRemaining(child: Center(child: Text('Error: $e'))),
          ),
          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final asset = await showModalBottomSheet<AssetEntity>(
            context: context,
            backgroundColor: Colors.transparent,
            builder: (ctx) => const PhotoPickerSheet(alreadyUsedAssetIds: []),
          );

          if (asset != null) {
            final file = await asset.file;
            if (file != null) {
              final latlng = await asset.latlngAsync();
              final location = latlng != null && latlng.latitude != 0
                  ? LatLng84(latlng.latitude, latlng.longitude)
                  : const LatLng84(39.9042, 116.4074); // Fallback to Beijing

              final newPhoto = MemoryPhoto(
                id: asset.id,
                imageUrl: file.path,
                location: location,
                timestamp: asset.createDateTime,
                description: 'Uploaded Photo',
              );

              final newAlbum = MemoryAlbum(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: 'New Footprint Memory',
                coverImageUrl: file.path, // Use local file for cover
                centerLocation: location,
                photos: [newPhoto],
              );

              MemoriesActions.createAlbum(newAlbum);

              // Navigate to the new album
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MemoryDetailPage(album: newAlbum),
                  ),
                );
              }
            }
          }
        },
        icon: const Icon(Icons.add_photo_alternate),
        label: Text(strings.addPhoto),
      ),
    );
  }
}