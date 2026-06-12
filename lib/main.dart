import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/main_layout.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(); // Override in main
});

void main() async {
  // 确保 Flutter 绑定初始化（用于后续地图、后台定位等插件）
  WidgetsFlutterBinding.ensureInitialized();
  
  final prefs = await SharedPreferences.getInstance();

  // ProviderScope 是 Riverpod 的根节点
  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '圆周旅迹 (Circular Travel)',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system, // Task 3.3: 跟随系统动态切换
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF4A90E2), brightness: Brightness.light),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade50,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: ZoomPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A90E2), 
          brightness: Brightness.dark,
          surface: const Color(0xFF1E1E1E), // 卡片颜色稍亮
        ),
        scaffoldBackgroundColor: const Color(0xFF121212), // 高级深空灰
        useMaterial3: true,
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