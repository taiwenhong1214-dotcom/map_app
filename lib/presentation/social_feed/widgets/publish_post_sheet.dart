import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../domain/entities/itinerary.dart';
import '../../../domain/entities/social_post.dart';
import '../providers/social_feed_provider.dart';

class PublishPostSheet extends ConsumerStatefulWidget {
  final Itinerary itinerary;

  const PublishPostSheet({super.key, required this.itinerary});

  @override
  ConsumerState<PublishPostSheet> createState() => _PublishPostSheetState();
}

class _PublishPostSheetState extends ConsumerState<PublishPostSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default title based on itinerary
    _titleController.text = 'My awesome trip to ${widget.itinerary.destination}';
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _publish() {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请输入标题！')),
      );
      return;
    }

    // Create a new post
    final newPost = SocialPost(
      id: 'post_${DateTime.now().millisecondsSinceEpoch}',
      authorName: 'Me (You)',
      authorAvatarUrl: 'https://i.pravatar.cc/150?img=68', // Random cute avatar
      title: _titleController.text,
      description: _descController.text.isNotEmpty 
          ? _descController.text 
          : 'Check out this amazing itinerary I generated using AI Planner!',
      coverImageUrl: 'https://images.unsplash.com/photo-1436491865332-7a61a109cc05?q=80&w=800&auto=format&fit=crop', // Default travel cover
      likesCount: 0,
      copyCount: 0,
      itinerary: widget.itinerary,
      postedAt: DateTime.now(),
    );

    // Add to feed
    ref.read(socialFeedProvider.notifier).addPost(newPost);

    Navigator.pop(context); // Close sheet
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('发布成功！去"社区发现"看看吧！')),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              const Text(
                '分享至社区',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
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
                    '${widget.itinerary.title} (${widget.itinerary.days.length} 天)',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Inputs
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: '取个响亮的标题',
              border: OutlineInputBorder(),
            ),
            maxLength: 30,
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _descController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: '说说这次行程的亮点吧...',
              border: OutlineInputBorder(),
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
              child: const Text('立即发布', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}