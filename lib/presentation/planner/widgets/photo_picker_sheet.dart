import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import '../../../core/i18n/app_strings.dart';

class PhotoPickerSheet extends StatefulWidget {
  final List<String> alreadyUsedAssetIds;

  const PhotoPickerSheet({super.key, required this.alreadyUsedAssetIds});

  @override
  State<PhotoPickerSheet> createState() => _PhotoPickerSheetState();
}

class _PhotoPickerSheetState extends State<PhotoPickerSheet> {
  List<AssetPathEntity> _albums = [];
  AssetPathEntity? _selectedAlbum;
  List<AssetEntity> _assets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlbums();
  }

  Future<void> _loadAlbums() async {
    final PermissionState ps = await PhotoManager.requestPermissionExtend();
    if (!ps.hasAccess) {
      if (mounted) {
        final strings = context.strings(Localizations.localeOf(context));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.photoPermissionRequired)));
        Navigator.pop(context);
      }
      return;
    }

    final List<AssetPathEntity> albums = await PhotoManager.getAssetPathList(type: RequestType.image);
    if (albums.isNotEmpty) {
      setState(() {
        _albums = albums;
        _selectedAlbum = albums.first;
      });
      await _fetchAssets();
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _fetchAssets() async {
    if (_selectedAlbum == null) return;
    setState(() => _isLoading = true);
    final photos = await _selectedAlbum!.getAssetListPaged(page: 0, size: 200);
    if (mounted) {
      setState(() {
        _assets = photos;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: _albums.isEmpty
                ? Text(context.strings(Localizations.localeOf(context)).selectPhotoToComplete, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))
                : DropdownButton<AssetPathEntity>(
                    value: _selectedAlbum,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    underline: const SizedBox(),
                    items: _albums.map((album) {
                      return DropdownMenuItem<AssetPathEntity>(
                        value: album,
                        child: FutureBuilder<int>(
                          future: album.assetCountAsync,
                          builder: (context, snapshot) {
                            final count = snapshot.data ?? 0;
                            return Text('${album.name} ($count)', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold));
                          },
                        ),
                      );
                    }).toList(),
                    onChanged: (album) {
                      if (album != null && album != _selectedAlbum) {
                        setState(() {
                          _selectedAlbum = album;
                        });
                        _fetchAssets();
                      }
                    },
                  ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _assets.isEmpty
                    ? const Center(child: Text('相册为空'))
                    : GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        physics: const BouncingScrollPhysics(),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                        ),
                        itemCount: _assets.length,
                        itemBuilder: (context, index) {
                          final asset = _assets[index];
                          final isUsed = widget.alreadyUsedAssetIds.contains(asset.id);

                          return GestureDetector(
                            onTap: isUsed
                                ? null
                                : () {
                                    Navigator.pop(context, asset);
                                  },
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: FutureBuilder<Uint8List?>(
                                    future: asset.thumbnailDataWithSize(const ThumbnailSize.square(200)),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.done && snapshot.data != null) {
                                        return Image.memory(
                                          snapshot.data!,
                                          fit: BoxFit.cover,
                                        );
                                      }
                                      return Container(color: Colors.grey.shade200);
                                    },
                                  ),
                                ),
                                if (isUsed)
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.black.withOpacity(0.6),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Center(
                                      child: Column(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.check_circle, color: Colors.white, size: 28),
                                          SizedBox(height: 4),
                                          Text('已在地图', style: TextStyle(color: Colors.white, fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
