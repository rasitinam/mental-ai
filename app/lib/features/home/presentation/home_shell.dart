import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
import '../../social/data/dm_badge.dart';
import '../../social/data/dm_entry.dart';

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
        (icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded, tooltip: l10n.navProfile),
      ];

  // Indices into both `_destinations` and the branch list in
  // `app/router.dart` — the two must stay in the same order.
  static const _storiesIndex = 2;
  static const _messagesIndex = 3;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final destinations = _destinations(AppLocalizations.of(context)!);
    final badgeVisible = ref.watch(dmBadgeProvider.select((s) => s.visible));
    final onMessagesRoot = navigationShell.currentIndex == _messagesIndex;

    return PopScope(
      // Only the Messages tab gets custom handling; every other tab
      // root keeps Android's normal "nothing left to pop, exit" back
      // behavior, exactly as before. This only ever fires at a branch's
      // *root* — a pushed page inside a branch (e.g. an open DM thread)
      // pops itself first, the same as any nested Navigator.
      canPop: !onMessagesRoot,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        // Reached from Settings' "Mesajlar" row → back goes back to the
        // settings list specifically (`context.go`, not `goBranch`,
        // since that tab's own root is now the profile view — see
        // `MyProfileScreen` — not the list this back should land on).
        // Reached straight from this tab bar → back falls through to
        // Stories, the app's landing tab, rather than exiting —
        // Messages sits right next to Stories for exactly this reason.
        final fromSettings = ref.read(dmEnteredFromSettingsProvider);
        ref.read(dmEnteredFromSettingsProvider.notifier).state = false;
        if (fromSettings) {
          context.go('/settings/list');
        } else {
          navigationShell.goBranch(_storiesIndex);
        }
      },
      child: Scaffold(
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
                // `Expanded` per icon rather than fixed widths: seven 44px
                // targets plus this bar's own margins need ~352px, which a
                // 320dp phone (or either half of a split screen) doesn't
                // have — they'd overflow and clip the last tab. Dividing
                // the available width instead means the bar fits any
                // screen and only the touch targets get tighter.
                child: Row(
                  children: [
                    for (var i = 0; i < destinations.length; i++)
                      Expanded(
                        child: _TabIcon(
                          data: destinations[i],
                          selected: i == navigationShell.currentIndex,
                          showBadge: i == _messagesIndex && badgeVisible,
                          color: palette.accent,
                          activeBackground: palette.accentSoft,
                          inactiveColor: palette.textSecondary,
                          badgeColor: palette.warning,
                          onTap: () {
                            // Tapping the tab directly is "straight from
                            // the bar", even if a stale flag was left set
                            // by an earlier Settings-row visit.
                            if (i == _messagesIndex) {
                              ref.read(dmEnteredFromSettingsProvider.notifier).state = false;
                            }
                            navigationShell.goBranch(
                              i,
                              initialLocation: i == navigationShell.currentIndex,
                            );
                          },
                        ),
                      ),
                  ],
                ),
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
    // Its `Expanded` parent hands over a share of the bar's width, which on
    // a wide screen is more than this needs and on a 320dp one is less. The
    // box stays a 44px square where there's room and shrinks to the share
    // where there isn't, so the bar never overflows and never stretches the
    // selected-tab highlight across the whole slot.
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.maxWidth.isFinite && constraints.maxWidth < 44
            ? constraints.maxWidth
            : 44.0;

        return Center(
          child: Tooltip(
            message: data.tooltip,
            child: InkResponse(
              onTap: onTap,
              radius: 28,
              highlightShape: BoxShape.circle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: side,
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
          ),
        );
      },
    );
  }
}
