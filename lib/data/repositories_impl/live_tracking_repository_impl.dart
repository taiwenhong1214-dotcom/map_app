import 'dart:async';
import 'dart:math';
import '../../../core/coordinate/coordinate_converter.dart';
import '../../domain/entities/live_location.dart';
import '../../domain/repositories/i_live_tracking_repository.dart';

class LiveTrackingRepositoryImpl implements ILiveTrackingRepository {
  final _streamController = StreamController<List<LiveLocation>>.broadcast();
  Timer? _mockTimer;
  LiveLocation? _myLastLocation;
  
  // 模拟两个好友，初始位置暂定为0，稍后会根据 _myLastLocation 在附近生成
  LiveLocation? _peer1;
  LiveLocation? _peer2;

  @override
  Stream<List<LiveLocation>> get peersLocationStream => _streamController.stream;

  @override
  Future<void> connectToRoom(String roomId, String userId) async {
    // 模拟连接耗时
    await Future.delayed(const Duration(milliseconds: 500));
    print('Connected to mock room: $roomId as $userId');

    // 启动一个定时器，每 2 秒向流里推一次好友的新坐标，模拟 WebSocket 接收数据
    _mockTimer?.cancel();
    _mockTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_myLastLocation == null) return;
      
      _updateMockPeers();
      
      final list = <LiveLocation>[];
      if (_peer1 != null) list.add(_peer1!);
      if (_peer2 != null) list.add(_peer2!);
      
      _streamController.add(list);
    });
  }

  @override
  Future<void> disconnect() async {
    _mockTimer?.cancel();
    _peer1 = null;
    _peer2 = null;
    print('Disconnected from mock room');
  }

  @override
  Future<void> broadcastMyPosition(LiveLocation location) async {
    _myLastLocation = location;
    // 在真正的 Supabase 环境中，这里是 channel.send(type: 'broadcast', event: 'position', payload: location.toJson())
    print('Broadcasting my position: ${location.position.latitude}, ${location.position.longitude}');
  }

  void _updateMockPeers() {
    if (_myLastLocation == null) return;
    
    // 初始化时在自己附近 500 米内生成
    if (_peer1 == null) {
      _peer1 = LiveLocation(
        userId: 'mock_user_1',
        userName: 'Alice',
        position: _generateRandomPointNear(_myLastLocation!.position, 0.005), // 约 500米
        updatedAt: DateTime.now(),
      );
    } else {
      // 随机乱动（步长很小，防止乱飞）
      _peer1 = _peer1!.copyWith(
        position: _generateRandomPointNear(_peer1!.position, 0.0001), 
        updatedAt: DateTime.now(),
      );
    }

    if (_peer2 == null) {
      _peer2 = LiveLocation(
        userId: 'mock_user_2',
        userName: 'Bob',
        position: _generateRandomPointNear(_myLastLocation!.position, 0.003),
        updatedAt: DateTime.now(),
      );
    } else {
      _peer2 = _peer2!.copyWith(
        position: _generateRandomPointNear(_peer2!.position, 0.0001), 
        updatedAt: DateTime.now(),
      );
    }
  }

  LatLng84 _generateRandomPointNear(LatLng84 center, double offset) {
    final random = Random();
    final dLat = (random.nextDouble() - 0.5) * 2 * offset;
    final dLng = (random.nextDouble() - 0.5) * 2 * offset;
    return LatLng84(center.latitude + dLat, center.longitude + dLng);
  }
}
