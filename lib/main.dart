import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'presentation/main_layout.dart';

void main() {
  // 确保 Flutter 绑定初始化（用于后续地图、后台定位等插件）
  WidgetsFlutterBinding.ensureInitialized();
  
  // ProviderScope 是 Riverpod 的根节点
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '圆周旅迹 (Circular Travel)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A90E2)),
        useMaterial3: true,
        // 全局设定顺滑滑动物理效果
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      home: const MainLayout(), // 引入带底部导航的主布局
    );
  }
}