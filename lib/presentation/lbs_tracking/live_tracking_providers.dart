import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'lbs_providers.dart';
import '../../domain/entities/live_location.dart';
import '../../domain/repositories/i_live_tracking_repository.dart';
import '../../data/repositories_impl/firebase_live_tracking_repository_impl.dart';
import 'package:home_widget/home_widget.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../../core/background_task/foreground_task_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter/foundation.dart';
import '../../core/coordinate/coordinate_converter.dart';

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
  DateTime? _lastHostUpdateTime;
  DateTime? _hostLastUpdatedAtValue;

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

    // 请求定位权限，否则后台服务无法获取定位
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return false;
    }
    if (permission == LocationPermission.deniedForever) return false;

    // Android 13/14 必须的前置权限请求
    // Do not return false if denied, as background tracking can still work without notifications on some OS versions.
    // Also prevents the 'double-click to join' bug where the prompt makes it return false immediately.
    await FlutterForegroundTask.requestNotificationPermission();
    
    // 初始化并启动前台服务 (Foreground Service)
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'live_tracking',
        channelName: 'Live Tracking',
        channelDescription: 'Keeps location tracking active in the background.',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(5000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    // 必须在 startService 之前保存数据！否则后台 Isolate 初始化时会读到空缓存，导致永远无法上传定位！
    await FlutterForegroundTask.saveData(key: 'roomId', value: roomId);
    await FlutterForegroundTask.saveData(key: 'userId', value: userId);
    await FlutterForegroundTask.saveData(key: 'userName', value: userName);

    final reqResult = await FlutterForegroundTask.requestIgnoreBatteryOptimization();
    
    await FlutterForegroundTask.startService(
      notificationTitle: 'Live Tracking Active',
      notificationText: 'Sharing location...',
      callback: startCallback,
    );

    // 🌟 终极保底方案：在主 Isolate 启动定时器双重上传！
    // 只要前台服务活着，主 Isolate 就不会被杀，定时器能完美工作，彻底绕开 Isolate 间变量丢失的深坑
    _locationTimer?.cancel();
    _locationTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (!state.isConnected) return;
      
      // 🌟 访客检测房主是否存活 (防止房主杀后台导致访客被永远挂载在房间里)
      if (!state.isHost && state.roomId != null) {
        try {
          final hostPeer = state.peers.firstWhere((p) => p.userId == state.roomId);
          if (_hostLastUpdatedAtValue != hostPeer.updatedAt) {
            _hostLastUpdatedAtValue = hostPeer.updatedAt;
            _lastHostUpdateTime = DateTime.now();
          } else if (_lastHostUpdateTime != null && DateTime.now().difference(_lastHostUpdateTime!).inSeconds > 25) {
            // 房主超过 25 秒没有位置更新，大概率已经杀后台了，自动踢出访客
            debugPrint('⚠️ Host timeout detected, auto disconnecting guest...');
            disconnect();
          }
        } catch (e) {
          // 找不到房主（可能被删了）
        }
      }

      try {
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );
        final loc = LiveLocation(
          userId: userId,
          userName: userName,
          position: LatLng84(position.latitude, position.longitude),
          updatedAt: DateTime.now(),
        );
        await repo.broadcastMyPosition(loc);
      } catch (e) {
        debugPrint('Main Isolate location upload error: $e');
      }
    });
    
    return true;
  }

  Future<void> disconnect() async {
    final wasHost = state.isHost;
    final cachedRoomId = state.roomId;
    
    state = LiveTrackingState(); // 立即重置状态，触发 UI 响应并防止重入
    FlutterForegroundTask.stopService();
    _locationTimer?.cancel();
    
    try {
      // 恢复小组件状态
      await HomeWidget.saveWidgetData<String>('widget_tracking_active', 'false');
      await HomeWidget.updateWidget(androidName: 'LiveTrackingWidgetProvider');

      if (wasHost && cachedRoomId != null) {
        await ref.read(liveTrackingRepositoryProvider).deleteRoom(cachedRoomId);
      }
      await ref.read(liveTrackingRepositoryProvider).disconnect();
    } catch (e) {
      debugPrint('Error during disconnect: $e');
    }
  }
}

final liveTrackingProvider = NotifierProvider<LiveTrackingNotifier, LiveTrackingState>(() {
  return LiveTrackingNotifier();
});

final roomItineraryStreamProvider = StreamProvider<Map<String, dynamic>?>((ref) {
  return ref.watch(liveTrackingRepositoryProvider).roomItineraryStream;
});
