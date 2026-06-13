import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/itinerary.dart';
import '../../../domain/entities/social_post.dart';
import '../providers/social_feed_provider.dart';
import 'dart:io';
import 'package:photo_manager/photo_manager.dart';
import '../../planner/widgets/photo_picker_sheet.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/i18n/locale_provider.dart';
import '../../../main.dart';
import 'dart:math';
import '../../../data/services/image_upload_service.dart';

class PublishPostSheet extends ConsumerStatefulWidget {
  final Itinerary itinerary;

  const PublishPostSheet({super.key, required this.itinerary});

  @override
  ConsumerState<PublishPostSheet> createState() => _PublishPostSheetState();
}

class _PublishPostSheetState extends ConsumerState<PublishPostSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _authorController = TextEditingController();
  String? _selectedCoverPath;
  String _avatarUrl = 'https://i.pravatar.cc/150?img=68';
  bool _isUploadingAvatar = false;

  @override
  void initState() {
    super.initState();
    // Default title based on itinerary
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_titleController.text.isEmpty) {
      final locale = ref.read(localeProvider);
      final strings = context.strings(locale);
      _titleController.text = strings.publishSheetTitle(widget.itinerary.destination);
    }
    if (_authorController.text.isEmpty) {
      _authorController.text = ref.read(sharedPreferencesProvider).getString('author_name') ?? '';
      _avatarUrl = ref.read(sharedPreferencesProvider).getString('author_avatar') ?? 'https://i.pravatar.cc/150?img=68';
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _authorController.dispose();
    super.dispose();
  }

  Future<void> _publish() async {
    final locale = ref.read(localeProvider);
    final strings = context.strings(locale);

    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.enterTitlePrompt)),
      );
      return;
    }

    if (_authorController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.authorNameRequired)),
      );
      return;
    }

    // Save author name for next time
    ref.read(sharedPreferencesProvider).setString('author_name', _authorController.text.trim());

    // Ensure device id exists
    String? deviceId = ref.read(sharedPreferencesProvider).getString('device_id');
    if (deviceId == null) {
      deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
      ref.read(sharedPreferencesProvider).setString('device_id', deviceId);
    }

    // Create a new post
    final newPost = SocialPost(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      authorName: _authorController.text.trim(),
      authorId: deviceId,
      authorAvatarUrl: _avatarUrl,
      title: _titleController.text,
      description: _descController.text.isNotEmpty 
          ? _descController.text 
          : strings.defaultPostDesc,
      coverImageUrl: _selectedCoverPath ?? 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?q=80&w=800&auto=format&fit=crop', // Default travel cover
      likesCount: 0,
      copyCount: 0,
      itinerary: widget.itinerary,
      postedAt: DateTime.now(),
    );

    // Upload image and save post to Firestore
    await SocialFeedActions.addPost(
      newPost, 
      localCoverImage: _selectedCoverPath != null ? File(_selectedCoverPath!) : null,
    );

    if (mounted) {
      Navigator.pop(context, true);
    } // Close sheet
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(strings.publishSuccess)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final strings = context.strings(locale);

    // Determine bottom padding for keyboard
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: bottomInset > 0 ? bottomInset + 24 : 40,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                strings.publishSheetHeader,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Preview snippet
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                const Icon(Icons.map, color: Colors.blueAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${widget.itinerary.title} (${strings.daysCount(widget.itinerary.days.length)})',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Cover Image Selection
          GestureDetector(
            onTap: () async {
              final AssetEntity? asset = await showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                builder: (ctx) => const PhotoPickerSheet(alreadyUsedAssetIds: []),
              );
              if (asset != null) {
                final file = await asset.file;
                if (file != null) {
                  setState(() {
                    _selectedCoverPath = file.path;
                  });
                }
              }
            },
            child: Container(
              height: 120,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
                image: _selectedCoverPath != null
                    ? DecorationImage(
                        image: FileImage(File(_selectedCoverPath!)),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: _selectedCoverPath == null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo, color: Colors.grey.shade500, size: 32),
                        const SizedBox(height: 8),
                        Text(strings.setCoverPhoto, style: TextStyle(color: Colors.grey.shade600)),
                      ],
                    )
                  : const Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          backgroundColor: Colors.black54,
                          radius: 14,
                          child: Icon(Icons.edit, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              GestureDetector(
                onTap: _isUploadingAvatar ? null : () async {
                  final AssetEntity? asset = await showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (ctx) => const PhotoPickerSheet(alreadyUsedAssetIds: []),
                  );
                  if (asset != null) {
                    final file = await asset.file;
                    if (file != null) {
                      setState(() => _isUploadingAvatar = true);
                      try {
                        final url = await ImageUploadService.uploadImage(file);
                        if (url != null) {
                          setState(() {
                            _avatarUrl = url;
                            _isUploadingAvatar = false;
                          });
                          ref.read(sharedPreferencesProvider).setString('author_avatar', url);
                        } else {
                          setState(() => _isUploadingAvatar = false);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.avatarUploadFailedEmpty)));
                        }
                      } catch (e) {
                        setState(() => _isUploadingAvatar = false);
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(strings.avatarUploadFailed)));
                      }
                    }
                  }
                },
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: NetworkImage(_avatarUrl),
                    ),
                    if (_isUploadingAvatar)
                      const CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    if (!_isUploadingAvatar)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 12),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  controller: _authorController,
                  decoration: InputDecoration(
                    labelText: strings.authorNameLabel,
                    hintText: strings.authorNameHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Inputs
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              labelText: strings.titleHint,
              border: const OutlineInputBorder(),
            ),
            maxLength: 30,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: InputDecoration(
              labelText: strings.descHint,
              border: const OutlineInputBorder(),
            ),
            maxLength: 150,
          ),
          const SizedBox(height: 24),

          // Publish Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: _publish,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Text(strings.publishBtn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}