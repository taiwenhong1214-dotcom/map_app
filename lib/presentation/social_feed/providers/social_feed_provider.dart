import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/social_post.dart';
import '../../../domain/entities/itinerary.dart';
import '../../../data/services/image_upload_service.dart';

final socialFeedProvider = StreamProvider<List<SocialPost>>((ref) {
  return FirebaseFirestore.instance
      .collection('social_posts')
      .orderBy('postedAt', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Override id with document ID
      return SocialPost.fromJson(data);
    }).toList();
  });
});

class SocialFeedActions {
  static Future<void> toggleLike(String postId, bool currentlyLiked) async {
    final docRef = FirebaseFirestore.instance.collection('social_posts').doc(postId);
    await docRef.update({
      'likesCount': FieldValue.increment(currentlyLiked ? -1 : 1),
    });
    // Local 'isLikedByMe' state should be managed separately if we don't have auth,
    // but for now, we just update the global count.
  }

  static Future<void> incrementCopy(String postId) async {
    final docRef = FirebaseFirestore.instance.collection('social_posts').doc(postId);
    await docRef.update({
      'copyCount': FieldValue.increment(1),
    });
  }

  static Future<void> addPost(SocialPost newPost, {File? localCoverImage}) async {
    String finalCoverUrl = newPost.coverImageUrl;
    
    // If there is a local image, upload it first to Catbox
    if (localCoverImage != null) {
      final uploadedUrl = await ImageUploadService.uploadImage(localCoverImage);
      if (uploadedUrl != null) {
        finalCoverUrl = uploadedUrl;
      }
    }

    final postToSave = newPost.copyWith(coverImageUrl: finalCoverUrl);
    final json = postToSave.toJson();
    json.remove('id'); // Firestore will auto-generate the ID
    
    await FirebaseFirestore.instance.collection('social_posts').add(json);
  }

  static Future<void> deletePost(String postId) async {
    await FirebaseFirestore.instance.collection('social_posts').doc(postId).delete();
  }
}