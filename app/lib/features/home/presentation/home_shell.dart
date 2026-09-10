import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';

/// Wraps every top-level tab in a floating glass tab bar instead of a
/// full-width Material [NavigationBar] — closer to how iOS floats a
/// control surface over content than to the edge-to-edge bar most
/// Material/AI-generated UIs default to. Icon-only by design: seven
/// destinations is already past Apple's own five-tab guidance, so adding
/// labels on top would force everything to shrink into unreadable text;
/// each screen already states its own name in its app bar.
///
/// The story feed sits dead centre because it's the app's landing screen
/// and the one destination people come back to without a task in mind.
/// The journal is a branch too (see `app/router.dart`) but deliberately
/// not a tab — it's reached from the home screen instead.
class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({super.key, required this.navigationShell});

  static List<({IconData icon, IconData activeIcon, String tooltip})> _destinations(
    AppLocalizations l10n,
  ) =>
      [
        (icon: Icons.event_note_outlined, activeIcon: Icons.event_note, tooltip: l10n.navReport),
        (icon: Icons.emoji_emotions_outlined, activeIcon: Icons.emoji_emotions, tooltip: l10n.navMood),
        (icon: Icons.forum_outlined, activeIcon: Icons.forum, tooltip: l10n.navChat),
        (icon: Icons.auto_stories_outlined, activeIcon: Icons.auto_stories, tooltip: l10n.navStories),
        (icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome, tooltip: l10n.navGuide),
        (icon: Icons.insights_outlined, activeIcon: Icons.insights, tooltip: l10n.navLife),
        (icon: Icons.tune_outlined, activeIcon: Icons.tune, tooltip: l10n.navSettings),
      ];

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final destinations = _destinations(AppLocalizations.of(context)!);

    return Scaffold(
      extendBody: true,
      body: navigationShell,
      // The one surface in the app with real content moving underneath it,
      // so the one that keeps a backdrop blur — and its own layer, so a
      // scrolling list above doesn't repaint the bar every frame.
      bottomNavigationBar: RepaintBoundary(
        child: SafeArea(
          minimum: const EdgeInsets.fromLTRB(14, 0, 14, 20),
          child: SizedBox(
            height: 60,
            child: GlassSurface(
              radius: 22,
              blur: true,
              bordered: true,
              blurSigma: 16,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  for (var i = 0; i < destinations.length; i++)
                    _TabIcon(
                      data: destinations[i],
                      selected: i == navigationShell.currentIndex,
                      color: palette.accent,
                      activeBackground: palette.accentSoft,
                      inactiveColor: palette.textSecondary,
                      onTap: () => navigationShell.goBranch(
                        i,
                        initialLocation: i == navigationShell.currentIndex,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabIcon extends StatelessWidget {
  final ({IconData icon, IconData activeIcon, String tooltip}) data;
  final bool selected;
  final Color color;
  final Color activeBackground;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _TabIcon({
    required this.data,
    required this.selected,
    required this.color,
    required this.activeBackground,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: data.tooltip,
      child: InkResponse(
        onTap: onTap,
        radius: 28,
        highlightShape: BoxShape.circle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: selected ? activeBackground : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: Icon(
            selected ? data.activeIcon : data.icon,
            size: 21,
            color: selected ? color : inactiveColor,
          ),
        ),
      ),
    );
  }
}
