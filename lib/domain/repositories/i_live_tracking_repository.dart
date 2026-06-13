import '../entities/live_location.dart';

abstract class ILiveTrackingRepository {
  /// Check if a room exists before connecting
  Future<bool> checkRoomExists(String roomId);

  /// Connect to a specific trip room
  Future<void> connectToRoom(String roomId, String userId);

  /// Disconnect from the room
  Future<void> disconnect();

  /// Delete the room entirely (Host only)
  Future<void> deleteRoom(String roomId);

  /// Broadcast local position to the room
  Future<void> broadcastMyPosition(LiveLocation location);

  /// Stream of other users' locations in the room
  Stream<List<LiveLocation>> get peersLocationStream;

  /// Stream of the room's itinerary (synced from host)
  Stream<Map<String, dynamic>?> get roomItineraryStream;

  /// Sync itinerary to the room (Host only)
  Future<void> syncItinerary(Map<String, dynamic> itineraryJson);
}
