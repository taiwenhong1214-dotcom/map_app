import 'package:flutter/material.dart';
import 'planner/pages/planner_page.dart';
import 'memories/pages/memories_page.dart';
import 'social_feed/pages/social_feed_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final pages = const [
      PlannerPage(),
      SocialFeedPage(),
      MemoriesPage(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        elevation: 8,
        indicatorColor: Colors.blueAccent.withValues(alpha: 0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore, color: Colors.blueAccent),
            label: 'AI 规划',
          ),
          NavigationDestination(
            icon: Icon(Icons.public_outlined),
            selectedIcon: Icon(Icons.public, color: Colors.blueAccent),
            label: '社区发现',
          ),
          NavigationDestination(
            icon: Icon(Icons.photo_library_outlined),
            selectedIcon: Icon(Icons.photo_library, color: Colors.blueAccent),
            label: '旅迹相册',
          ),
        ],
      ),
    );
  }
}