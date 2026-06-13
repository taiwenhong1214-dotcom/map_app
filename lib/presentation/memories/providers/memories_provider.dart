import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../domain/entities/memory.dart';
import '../../../data/services/image_upload_service.dart';

final memoriesProvider = StreamProvider<List<MemoryAlbum>>((ref) {
  return FirebaseFirestore.instance
      .collection('memories')
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Override id with document ID
      return MemoryAlbum.fromJson(data);
    }).toList();
  });
});

class MemoriesActions {
  static Future<void> createAlbum(MemoryAlbum album) async {
    // If the coverImageUrl is a local path, upload it
    String finalCoverUrl = album.coverImageUrl;
    if (!finalCoverUrl.startsWith('http')) {
      final uploadedUrl = await ImageUploadService.uploadImage(File(finalCoverUrl));
      if (uploadedUrl != null) {
        finalCoverUrl = uploadedUrl;
      }
    }

    // Also upload the first photo if it exists
    final updatedPhotos = <MemoryPhoto>[];
    for (var photo in album.photos) {
      if (!photo.imageUrl.startsWith('http')) {
        final uploadedPhotoUrl = await ImageUploadService.uploadImage(File(photo.imageUrl));
        if (uploadedPhotoUrl != null) {
          updatedPhotos.add(MemoryPhoto(
            id: photo.id,
            imageUrl: uploadedPhotoUrl,
            location: photo.location,
            timestamp: photo.timestamp,
            description: photo.description,
          ));
        } else {
          updatedPhotos.add(photo);
        }
      } else {
        updatedPhotos.add(photo);
      }
    }

    final albumToSave = MemoryAlbum(
      id: album.id,
      title: album.title,
      coverImageUrl: finalCoverUrl,
      centerLocation: album.centerLocation,
      photos: updatedPhotos,
    );

    final json = albumToSave.toJson();
    json.remove('id'); // Firestore will auto-generate

    await FirebaseFirestore.instance.collection('memories').add(json);
  }

  static Future<void> addPhotoToAlbum(String albumId, MemoryPhoto photo) async {
    String finalImageUrl = photo.imageUrl;
    if (!finalImageUrl.startsWith('http')) {
      final uploadedUrl = await ImageUploadService.uploadImage(File(finalImageUrl));
      if (uploadedUrl != null) {
        finalImageUrl = uploadedUrl;
      }
    }

    final photoToSave = MemoryPhoto(
      id: photo.id,
      imageUrl: finalImageUrl,
      location: photo.location,
      timestamp: photo.timestamp,
      description: photo.description,
    );

    final docRef = FirebaseFirestore.instance.collection('memories').doc(albumId);
    
    // Add to 'photos' array using FieldValue.arrayUnion
    await docRef.update({
      'photos': FieldValue.arrayUnion([photoToSave.toJson()]),
    });
  }
}