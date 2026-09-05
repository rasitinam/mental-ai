import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Wraps every top-level tab in a persistent bottom nav bar. Receives the
/// [StatefulShellRoute]'s navigation shell from `router.dart` so switching
/// tabs doesn't rebuild each tab's widget tree from scratch.
class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({super.key, required this.navigationShell});

  static const _destinations = [
    NavigationDestination(icon: Icon(Icons.today_outlined), selectedIcon: Icon(Icons.today), label: 'Rapor'),
    NavigationDestination(icon: Icon(Icons.mood_outlined), selectedIcon: Icon(Icons.mood), label: 'Ruh Hali'),
    NavigationDestination(icon: Icon(Icons.book_outlined), selectedIcon: Icon(Icons.book), label: 'Günlük'),
    NavigationDestination(icon: Icon(Icons.chat_bubble_outline), selectedIcon: Icon(Icons.chat_bubble), label: 'Sohbet'),
    NavigationDestination(icon: Icon(Icons.lightbulb_outline), selectedIcon: Icon(Icons.lightbulb), label: 'İçgörüler'),
    NavigationDestination(icon: Icon(Icons.timeline_outlined), selectedIcon: Icon(Icons.timeline), label: 'Yaşam'),
    NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings), label: 'Ayarlar'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: _destinations,
      ),
    );
  }
}
