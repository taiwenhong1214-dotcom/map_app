import 'dart:async';
import 'dart:isolate';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:home_widget/home_widget.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:ui';
import 'package:flutter/widgets.dart';
import '../../firebase_options.dart';
import '../../data/repositories_impl/firebase_live_tracking_repository_impl.dart';
import '../../domain/entities/live_location.dart';
import '../coordinate/coordinate_converter.dart';

// The callback function should always be a top-level function.
@pragma('vm:entry-point')
void startCallback() {
  // The setTaskHandler function must be called to handle the task in the background.
  FlutterForegroundTask.setTaskHandler(ForegroundTaskHandler());
}

class ForegroundTaskHandler extends TaskHandler {
  FirebaseLiveTrackingRepositoryImpl? _repository;
  String? _roomId;
  String? _userId;
  String? _userName;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    // Re-initialize Firebase in this isolate
    try {
      DartPluginRegistrant.ensureInitialized();
      WidgetsFlutterBinding.ensureInitialized();
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _repository = FirebaseLiveTrackingRepositoryImpl();
    } catch (e) {
      debugPrint('Error initializing Firebase in ForegroundTask: $e');
    }
  }

  @override
  void onRepeatEvent(DateTime timestamp) async {
    // 获取可靠的本地化数据
    final roomId = await FlutterForegroundTask.getData<String>(key: 'roomId');
    final userId = await FlutterForegroundTask.getData<String>(key: 'userId');
    final userName = await FlutterForegroundTask.getData<String>(key: 'userName');

    if (_repository == null || roomId == null || userId == null) return;

    try {
      final Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final liveLocation = LiveLocation(
        userId: userId,
        userName: userName ?? 'Unknown',
        position: LatLng84(position.latitude, position.longitude),
        updatedAt: DateTime.now(),
      );

      // Reconnect to room just in case this isolate lost connection state
      await _repository!.connectToRoom(roomId, userId);
      await _repository!.broadcastMyPosition(liveLocation);
      
      // Update the foreground notification
      FlutterForegroundTask.updateService(
        notificationTitle: 'Live Tracking Active',
        notificationText: 'Sharing location... \nLat: ${position.latitude.toStringAsFixed(4)}, Lng: ${position.longitude.toStringAsFixed(4)}',
      );

      // Update the Desktop Widget
      await HomeWidget.saveWidgetData<String>('widget_tracking_active', 'true');
      await HomeWidget.saveWidgetData<String>('widget_message', '防走散中... Lat: ${position.latitude.toStringAsFixed(2)}');
      await HomeWidget.updateWidget(androidName: 'LiveTrackingWidgetProvider');

    } catch (e) {
      debugPrint('ForegroundTask location error: $e');
    }
  }

  @override
  Future<void> onDestroy(DateTime timestamp, bool isTimeout) async {
    await _repository?.disconnect();
  }

  @override
  void onReceiveData(Object data) {
    // We now use SharedPreferences (getData) to avoid race conditions.
  }

  @override
  void onNotificationButtonPressed(String id) {
    if (id == 'stop_tracking') {
      FlutterForegroundTask.stopService();
    }
  }

  @override
  void onNotificationPressed() {
    FlutterForegroundTask.launchApp();
  }
}
