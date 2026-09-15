import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../domain/life_story.dart';
import 'story_detail_screen.dart';

/// One square preview in a "post grid" of a person's own stories —
/// shared between [MyProfileScreen]'s embedded grid and the dedicated
/// [MyStoriesScreen], so the two read as the same object rather than two
/// slightly different reimplementations of it. Text stands in for the
/// photo a real post grid would show: the diagnosis category's emoji, a
/// status dot, and a few lines of the body.
class StoryGridTile extends StatelessWidget {
  final LifeStory story;
  final ({String emoji, String name})? tag;
  final AppPalette palette;
  final VoidCallback onTap;

  const StoryGridTile({
    super.key,
    required this.story,
    required this.tag,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.glassFill,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (tag != null) Text(tag!.emoji, style: const TextStyle(fontSize: 14)),
                      const Spacer(),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: storyStatusColor(palette, story.status),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      story.body,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.35,
                        fontWeight: FontWeight.w400,
                        color: palette.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (story.anonymous)
              Positioned(
                right: 6,
                bottom: 6,
                child: Icon(Icons.visibility_off_rounded, size: 12, color: palette.textTertiary),
              ),
          ],
        ),
      ),
    );
  }
}

/// The grid's own "write a new one" tile — square, styled to sit flush
/// among [StoryGridTile]s rather than as a separate floating control.
class AddStoryTile extends StatelessWidget {
  final AppPalette palette;
  final VoidCallback onTap;

  const AddStoryTile({super.key, required this.palette, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: palette.glassFill,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Center(
          child: Icon(Icons.add_rounded, size: 26, color: palette.accent),
        ),
      ),
    );
  }
}
