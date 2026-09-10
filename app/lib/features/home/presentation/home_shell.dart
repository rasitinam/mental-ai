import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
import '../../social/data/dm_badge.dart';

/// Wraps every top-level tab in a floating glass tab bar instead of a
/// full-width Material [NavigationBar] — closer to how iOS floats a
/// control surface over content than to the edge-to-edge bar most
/// Material/AI-generated UIs default to. Icon-only by design: seven
/// destinations is already past Apple's own five-tab guidance, so adding
/// labels on top would force everything to shrink into unreadable text;
/// each screen already states its own name in its app bar.
///
/// The story feed sits dead centre because it's the app's landing screen
/// and the one destination people come back to without a task in mind,
/// with Messages immediately to its right. Mood and the journal are both
/// branches too (see `app/router.dart`) but deliberately not tabs — the
/// home screen's quick actions reach them instead, which keeps the bar at
/// seven icons instead of nine.
class HomeShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({super.key, required this.navigationShell});

  static List<({IconData icon, IconData activeIcon, String tooltip})> _destinations(
    AppLocalizations l10n,
  ) =>
      [
        (icon: Icons.event_note_outlined, activeIcon: Icons.event_note, tooltip: l10n.navReport),
        (icon: Icons.forum_outlined, activeIcon: Icons.forum, tooltip: l10n.navChat),
        (icon: Icons.auto_stories_outlined, activeIcon: Icons.auto_stories, tooltip: l10n.navStories),
        (icon: Icons.mail_outline_rounded, activeIcon: Icons.mail_rounded, tooltip: l10n.navMessages),
        (icon: Icons.auto_awesome_outlined, activeIcon: Icons.auto_awesome, tooltip: l10n.navGuide),
        (icon: Icons.insights_outlined, activeIcon: Icons.insights, tooltip: l10n.navLife),
        (icon: Icons.tune_outlined, activeIcon: Icons.tune, tooltip: l10n.navSettings),
      ];

  // Index into `_destinations` — must track the Messages entry's position
  // in both this list and the `/dm` branch's position in `app/router.dart`.
  static const _messagesIndex = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final destinations = _destinations(AppLocalizations.of(context)!);
    final badgeVisible = ref.watch(dmBadgeProvider.select((s) => s.visible));

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
                      showBadge: i == _messagesIndex && badgeVisible,
                      color: palette.accent,
                      activeBackground: palette.accentSoft,
                      inactiveColor: palette.textSecondary,
                      badgeColor: palette.warning,
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
  final bool showBadge;
  final Color color;
  final Color activeBackground;
  final Color inactiveColor;
  final Color badgeColor;
  final VoidCallback onTap;

  const _TabIcon({
    required this.data,
    required this.selected,
    required this.showBadge,
    required this.color,
    required this.activeBackground,
    required this.inactiveColor,
    required this.badgeColor,
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
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                selected ? data.activeIcon : data.icon,
                size: 21,
                color: selected ? color : inactiveColor,
              ),
              if (showBadge)
                Positioned(
                  top: -1,
                  right: -3,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: badgeColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
