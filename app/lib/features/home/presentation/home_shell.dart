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
class HomeShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({super.key, required this.navigationShell});

  static List<({IconData icon, IconData activeIcon, String tooltip})> _destinations(
    AppLocalizations l10n,
  ) =>
      [
        (icon: Icons.event_note_outlined, activeIcon: Icons.event_note, tooltip: l10n.navReport),
        (icon: Icons.emoji_emotions_outlined, activeIcon: Icons.emoji_emotions, tooltip: l10n.navMood),
        (icon: Icons.menu_book_outlined, activeIcon: Icons.menu_book, tooltip: l10n.navJournal),
        (icon: Icons.forum_outlined, activeIcon: Icons.forum, tooltip: l10n.navChat),
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
        minimum: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        child: GlassSurface(
          radius: 26,
          blur: true,
          blurSigma: 30,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 0; i < destinations.length; i++)
                _TabIcon(
                  data: destinations[i],
                  selected: i == navigationShell.currentIndex,
                  color: palette.accent,
                  inactiveColor: palette.textTertiary,
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
    );
  }
}

class _TabIcon extends StatelessWidget {
  final ({IconData icon, IconData activeIcon, String tooltip}) data;
  final bool selected;
  final Color color;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _TabIcon({
    required this.data,
    required this.selected,
    required this.color,
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
            color: selected ? color.withValues(alpha: 0.14) : Colors.transparent,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Icon(
            selected ? data.activeIcon : data.icon,
            size: 22,
            color: selected ? color : inactiveColor,
          ),
        ),
      ),
    );
  }
}
