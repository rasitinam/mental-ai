import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/life_story.dart';
import 'story_detail_screen.dart' show storyStatusLabel;

/// One square preview of a person's own story: its status on a small pill
/// and the first lines of the text, on a color that says the same thing —
/// peach once it's published, lilac while it's being reviewed.
class StoryGridTile extends StatelessWidget {
  final LifeStory story;
  final AppPalette palette;
  final VoidCallback onTap;

  /// The diagnosis this story is about; kept for callers that resolve it.
  final ({String emoji, String name})? tag;

  const StoryGridTile({
    super.key,
    required this.story,
    required this.palette,
    required this.onTap,
    this.tag,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final background = switch (story.status) {
      StoryStatus.approved => palette.peach,
      StoryStatus.pending => palette.lilac,
      StoryStatus.rejected => palette.surfaceMuted,
    };
    final foreground = AppPalette.inkOn(background);

    return Semantics(
      button: true,
      label: '${storyStatusLabel(l10n, story.status)}: ${story.body}',
      excludeSemantics: true,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(11),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Container(
                        height: 22,
                        padding: const EdgeInsets.symmetric(horizontal: 7),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppPalette.light.glassFill,
                          borderRadius: BorderRadius.circular(7),
                        ),
                        child: Text(
                          storyStatusLabel(l10n, story.status),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: AppPalette.light.textPrimary,
                            fontSize: 11.5,
                            height: 1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    if (story.anonymous) ...[
                      const SizedBox(width: 4),
                      Icon(Icons.visibility_off_outlined, size: 14, color: foreground.withValues(alpha: 0.7)),
                    ],
                  ],
                ),
                const Spacer(),
                Text(
                  story.body,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(color: foreground, fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The "write a new one" tile, first in the grid.
class AddStoryTile extends StatelessWidget {
  final AppPalette palette;
  final VoidCallback onTap;

  const AddStoryTile({super.key, required this.palette, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Semantics(
      button: true,
      label: l10n.storiesWriteCta,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(color: palette.textPrimary, width: 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, size: 24, color: palette.textPrimary),
              const SizedBox(height: 6),
              Text(l10n.meStoryNew,
                  style: AppTypography.label.copyWith(color: palette.textPrimary, fontSize: 14, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}
