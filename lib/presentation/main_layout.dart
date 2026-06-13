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
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          elevation: 0,
          backgroundColor: Colors.transparent,
          indicatorColor: Colors.transparent,
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.explore_outlined, color: Colors.grey),
              selectedIcon: Icon(Icons.explore, color: Theme.of(context).colorScheme.primary),
              label: strings.navPlanner,
            ),
            NavigationDestination(
              icon: const Icon(Icons.public_outlined, color: Colors.grey),
              selectedIcon: Icon(Icons.public, color: Theme.of(context).colorScheme.primary),
              label: strings.navDiscovery,
            ),
            NavigationDestination(
              icon: const Icon(Icons.photo_library_outlined, color: Colors.grey),
              selectedIcon: Icon(Icons.photo_library, color: Theme.of(context).colorScheme.primary),
              label: strings.navMemories,
            ),
          ],
        ),
      ),
    );
  }
}