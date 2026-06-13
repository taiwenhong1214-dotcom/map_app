import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lbs_providers.dart';
import '../../domain/entities/live_location.dart';
import '../../domain/repositories/i_live_tracking_repository.dart';
import '../../data/repositories_impl/firebase_live_tracking_repository_impl.dart';

// 1. Repository Provider
final liveTrackingRepositoryProvider = Provider<ILiveTrackingRepository>((ref) {
  return FirebaseLiveTrackingRepositoryImpl();
});

// 2. State definition
class LiveTrackingState {
  final bool isConnected;
  final String? roomId;
  final bool isHost;
  final List<LiveLocation> peers;

  LiveTrackingState({
    this.isConnected = false,
    this.roomId,
    this.isHost = false,
    this.peers = const [],
  });

  LiveTrackingState copyWith({
    bool? isConnected,
    String? roomId,
    bool? isHost,
    List<LiveLocation>? peers,
  }) {
    return LiveTrackingState(
      isConnected: isConnected ?? this.isConnected,
      roomId: roomId ?? this.roomId,
      isHost: isHost ?? this.isHost,
      peers: peers ?? this.peers,
    );
  }
}

// 3. Notifier
class LiveTrackingNotifier extends Notifier<LiveTrackingState> {
  StreamSubscription? _peersSub;
  Timer? _locationTimer;

  @override
  LiveTrackingState build() {
    // 监听 Repository 发来的好友位置流
    _peersSub = ref.watch(liveTrackingRepositoryProvider).peersLocationStream.listen((peers) {
      state = state.copyWith(peers: peers);
    });

    ref.onDispose(() {
      _peersSub?.cancel();
      _locationTimer?.cancel();
      ref.read(liveTrackingRepositoryProvider).disconnect();
    });

    return LiveTrackingState();
  }

  Future<bool> connect(String roomId, String userId, String userName, Map<String, dynamic>? initialItinerary) async {
    if (state.isConnected) return true;
    
    final repo = ref.read(liveTrackingRepositoryProvider);
    final isHost = initialItinerary != null;

    // 如果是访客，先检查房间是否存在
    if (!isHost) {
      final exists = await repo.checkRoomExists(roomId);
      if (!exists) return false;
    }

    await repo.connectToRoom(roomId, userId);
    state = state.copyWith(isConnected: true, roomId: roomId, isHost: isHost);

    if (isHost) {
      await repo.syncItinerary(initialItinerary);
    }

    // 核心逻辑：监听本地真实的 GPS 并节流广播
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      final currentLoc = ref.read(locationProvider).value;
      if (currentLoc != null) {
        repo.broadcastMyPosition(LiveLocation(
          userId: userId,
          userName: userName,
          avatarUrl: null,
          position: currentLoc,
          updatedAt: DateTime.now(),
        ));
      }
    });
    
    return true;
  }

  Future<void> disconnect() async {
    _locationTimer?.cancel();
    if (state.isHost && state.roomId != null) {
      await ref.read(liveTrackingRepositoryProvider).deleteRoom(state.roomId!);
    }
    await ref.read(liveTrackingRepositoryProvider).disconnect();
    state = LiveTrackingState(); // 重置状态
  }
}

final liveTrackingProvider = NotifierProvider<LiveTrackingNotifier, LiveTrackingState>(() {
  return LiveTrackingNotifier();
});

final roomItineraryStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  return ref.watch(liveTrackingRepositoryProvider).roomItineraryStream;
});
