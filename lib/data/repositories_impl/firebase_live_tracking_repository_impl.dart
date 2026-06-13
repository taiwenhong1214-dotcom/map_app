import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/live_location.dart';
import '../../domain/repositories/i_live_tracking_repository.dart';

class FirebaseLiveTrackingRepositoryImpl implements ILiveTrackingRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _streamController = StreamController<List<LiveLocation>>.broadcast();
  final _itineraryStreamController = StreamController<Map<String, dynamic>?>.broadcast();
  StreamSubscription? _roomSub;
  StreamSubscription? _itinerarySub;
  String? _currentRoomId;
  String? _myUserId;

  @override
  Stream<List<LiveLocation>> get peersLocationStream => _streamController.stream;

  @override
  Stream<Map<String, dynamic>?> get roomItineraryStream => _itineraryStreamController.stream;

  @override
  Future<bool> checkRoomExists(String roomId) async {
    try {
      final doc = await _firestore.collection('live_rooms').doc(roomId).get();
      return doc.exists;
    } catch (e) {
      print('Error checking room: $e');
      return false;
    }
  }

  @override
  Future<void> connectToRoom(String roomId, String userId) async {
    _currentRoomId = roomId;
    _myUserId = userId;

    _itinerarySub?.cancel();
    _itinerarySub = _firestore
        .collection('live_rooms')
        .doc(roomId)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        final data = snapshot.data()!;
        _itineraryStreamController.add(data['itinerary'] as Map<String, dynamic>?);

        final peersMap = data['peers'] as Map<String, dynamic>?;
        final peers = <LiveLocation>[];
        if (peersMap != null) {
          peersMap.forEach((key, value) {
            if (key != userId) { // Skip own
              try {
                peers.add(LiveLocation.fromJson(Map<String, dynamic>.from(value as Map)));
              } catch (e) {
                print('Error parsing peer: $e');
              }
            }
          });
        }
        _streamController.add(peers);
      } else {
        _itineraryStreamController.add(null);
        _streamController.add([]);
      }
    });
  }

  @override
  Future<void> disconnect() async {
    _itinerarySub?.cancel();
    _itinerarySub = null;

    if (_currentRoomId != null && _myUserId != null) {
      try {
        await _firestore.collection('live_rooms').doc(_currentRoomId).update({
          'peers.$_myUserId': FieldValue.delete(),
        });
      } catch (e) {
        print('Error deleting peer from room: $e');
      }
    }

    _currentRoomId = null;
    _myUserId = null;
    // Clear the streams
    _streamController.add([]);
    _itineraryStreamController.add(null);
  }

  @override
  Future<void> deleteRoom(String roomId) async {
    try {
      await _firestore.collection('live_rooms').doc(roomId).delete();
    } catch (e) {
      print('Error deleting room: $e');
    }
  }

  @override
  Future<void> broadcastMyPosition(LiveLocation location) async {
    if (_currentRoomId == null || _myUserId == null) return;

    try {
      await _firestore.collection('live_rooms').doc(_currentRoomId).set({
        'peers': {
          _myUserId!: location.toJson(),
        }
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error broadcasting position: $e');
    }
  }

  @override
  Future<void> syncItinerary(Map<String, dynamic> itineraryJson) async {
    if (_currentRoomId == null) return;
    try {
      await _firestore.collection('live_rooms').doc(_currentRoomId).set({
        'itinerary': itineraryJson,
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error syncing itinerary: $e');
    }
  }
}
