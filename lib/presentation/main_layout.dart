import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'planner/pages/planner_page.dart';
import 'memories/pages/memories_page.dart';
import 'social_feed/pages/social_feed_page.dart';
import '../core/i18n/app_strings.dart';
import '../core/i18n/locale_provider.dart';
import 'planner/providers/planner_providers.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({super.key});

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final strings = context.strings(locale);

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
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.explore_outlined),
            selectedIcon: const Icon(Icons.explore, color: Colors.blueAccent),
            label: strings.navPlanner,
          ),
          NavigationDestination(
            icon: const Icon(Icons.public_outlined),
            selectedIcon: const Icon(Icons.public, color: Colors.blueAccent),
            label: strings.navDiscovery,
          ),
          NavigationDestination(
            icon: const Icon(Icons.photo_library_outlined),
            selectedIcon: const Icon(Icons.photo_library, color: Colors.blueAccent),
            label: strings.navMemories,
          ),
        ],
      ),
    );
  }
}