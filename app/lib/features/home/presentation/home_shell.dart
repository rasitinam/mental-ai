import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../../social/data/dm_badge.dart';

/// Five labeled tabs on a solid bar — Bugün, Sohbet, Hikayeler, Yolum,
/// Ben — each with its own color, so the section you're in reads without
/// looking for the highlight.
///
/// The router has more branches than tabs: Messages lives under
/// Hikayeler, Rehber under Yolum, and the full mood and journal screens
/// under Bugün. Those branches light their parent tab, and Android back at
/// their root returns to it instead of exiting the app.
class HomeShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const HomeShell({super.key, required this.navigationShell});

  /// Branch index behind each tab, in tab order — see `app/router.dart`.
  static const _tabBranches = [0, 1, 2, 5, 6];

  /// Branches that aren't tabs, mapped to the branch of the tab they sit
  /// under.
  static const _parentBranch = {3: 2, 4: 5, 7: 0, 8: 0};

  static const _storiesTab = 2;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final current = navigationShell.currentIndex;
    final parent = _parentBranch[current];
    final selectedTab = _tabBranches.indexOf(parent ?? current);
    final badgeVisible = ref.watch(dmBadgeProvider.select((s) => s.visible));
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    final tabs = [
      _TabData(Icons.wb_twilight_rounded, Icons.wb_twilight_rounded, l10n.navToday, palette.sun),
      _TabData(Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, l10n.navChat, palette.sky),
      _TabData(Icons.auto_stories_outlined, Icons.auto_stories_rounded, l10n.navStories, palette.peach),
      _TabData(Icons.route_outlined, Icons.route_rounded, l10n.navPath, palette.mint),
      _TabData(Icons.person_outline_rounded, Icons.person_rounded, l10n.navMe, palette.lilac),
    ];

    return PopScope(
      canPop: parent == null,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || parent == null) return;
        navigationShell.goBranch(parent);
      },
      child: Scaffold(
        body: navigationShell,
        // Hidden while typing, so a composer isn't pushed up by a bar
        // nobody can reach with the keyboard open anyway.
        bottomNavigationBar: keyboardOpen
            ? null
            : DecoratedBox(
                decoration: BoxDecoration(
                  color: palette.canvasTop,
                  border: Border(top: BorderSide(color: palette.separator)),
                ),
                child: SafeArea(
                  top: false,
                  minimum: const EdgeInsets.only(bottom: 6),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 6, 8, 4),
                    child: Row(
                      children: [
                        for (var i = 0; i < tabs.length; i++)
                          Expanded(
                            child: _Tab(
                              data: tabs[i],
                              selected: i == selectedTab,
                              showBadge: i == _storiesTab && badgeVisible,
                              onTap: () {
                                final branch = _tabBranches[i];
                                navigationShell.goBranch(branch, initialLocation: branch == current);
                              },
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

class _TabData {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final Color color;
  const _TabData(this.icon, this.activeIcon, this.label, this.color);
}

class _Tab extends StatelessWidget {
  final _TabData data;
  final bool selected;
  final bool showBadge;
  final VoidCallback onTap;

  const _Tab({required this.data, required this.selected, required this.showBadge, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final foreground = selected ? palette.textPrimary : palette.textSecondary;

    return Semantics(
      button: true,
      selected: selected,
      label: data.label,
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Material(
          color: selected ? data.color : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              height: 58,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Icon(selected ? data.activeIcon : data.icon, size: 24, color: foreground),
                      if (showBadge)
                        Positioned(
                          top: -2,
                          right: -5,
                          child: Container(
                            width: 11,
                            height: 11,
                            decoration: BoxDecoration(
                              color: palette.ember,
                              shape: BoxShape.circle,
                              border: Border.all(color: selected ? data.color : palette.canvasTop, width: 2),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    data.label,
                    maxLines: 1,
                    overflow: TextOverflow.fade,
                    softWrap: false,
                    style: AppTypography.caption.copyWith(
                      fontSize: 12,
                      height: 1,
                      color: foreground,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
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
