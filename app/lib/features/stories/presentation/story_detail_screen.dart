import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
import '../../catalog/data/catalog_api.dart';
import '../../catalog/domain/disorder_category.dart';
import '../domain/life_story.dart';
import 'metoo.dart';
import 'stories_controller.dart';
import 'story_submit_screen.dart';

String storyStatusLabel(AppLocalizations l10n, StoryStatus status) => switch (status) {
      StoryStatus.pending => l10n.storiesStatusPending,
      StoryStatus.approved => l10n.storiesStatusApproved,
      StoryStatus.rejected => l10n.storiesStatusRejected,
    };

Color storyStatusColor(AppPalette palette, StoryStatus status) => switch (status) {
      StoryStatus.pending => palette.textSecondary,
      StoryStatus.approved => palette.accent,
      StoryStatus.rejected => palette.warning,
    };

/// The full text behind one grid tile in [MyStoriesScreen] — a square is
/// only ever a preview, so opening one needs somewhere to read the whole
/// thing and act on it (edit, withdraw). Takes an id and watches the
/// controller rather than taking a [LifeStory] by value, so saving an
/// edit and popping back here shows the fresh copy instead of what this
/// screen was first pushed with.
class StoryDetailScreen extends ConsumerWidget {
  final String storyId;
  const StoryDetailScreen({super.key, required this.storyId});

  ({String emoji, String name})? _resolve(List<DisorderCategory> categories, String slug) {
    for (final category in categories) {
      for (final disorder in category.disorders) {
        if (disorder.slug == slug) return (emoji: category.emoji, name: disorder.name);
      }
    }
    return null;
  }

  Future<void> _edit(BuildContext context, LifeStory story) async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => StorySubmitScreen(editing: story)),
    );
  }

  Future<void> _confirmWithdraw(BuildContext context, WidgetRef ref, AppLocalizations l10n, String id) async {
    final palette = AppPalette.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: palette.glassFill,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(l10n.storiesWithdrawTitle,
            style: AppTypography.headline.copyWith(color: palette.textPrimary, fontSize: 17)),
        content: Text(l10n.storiesWithdrawBody,
            style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(l10n.commonCancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.storiesWithdraw, style: TextStyle(color: palette.warning)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(storiesControllerProvider.notifier).withdraw(id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final mine = ref.watch(storiesControllerProvider.select((s) => s.mine));
    final categories = ref.watch(categoriesProvider).valueOrNull ?? const <DisorderCategory>[];

    LifeStory? story;
    for (final s in mine) {
      if (s.id == storyId) {
        story = s;
        break;
      }
    }

    // Withdrawn (by this screen or elsewhere) while it was open — pop
    // once rather than render a detail screen for a story that's gone.
    if (story == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      });
      return const Scaffold(body: SizedBox.shrink());
    }

    final tag = _resolve(categories, story.diagnosisSlug);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
              child: Row(
                children: [
                  SquareIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () => _edit(context, story!),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.edit_outlined, size: 20, color: palette.textSecondary),
                    ),
                  ),
                  InkWell(
                    onTap: () => _confirmWithdraw(context, ref, l10n, story!.id),
                    borderRadius: BorderRadius.circular(10),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Icon(Icons.delete_outline_rounded, size: 20, color: palette.warning),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(22, 0, 22, bottomClearance(context)),
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _Badge(
                        label: storyStatusLabel(l10n, story.status),
                        color: storyStatusColor(palette, story.status),
                        palette: palette,
                      ),
                      if (story.anonymous)
                        _Badge(
                          label: l10n.storiesAnonymous,
                          color: palette.textSecondary,
                          palette: palette,
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (tag != null)
                    Row(
                      children: [
                        Text(tag.emoji, style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text(tag.name,
                            style: AppTypography.label
                                .copyWith(color: palette.textPrimary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  const SizedBox(height: 16),
                  GlassSurface(
                    radius: 18,
                    child: Text(
                      story.body,
                      style: AppTypography.body.copyWith(color: palette.textPrimary),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    DateFormat.yMMMMd(Localizations.localeOf(context).languageCode).format(story.createdAt),
                    style: AppTypography.caption.copyWith(color: palette.textSecondary),
                  ),
                  if (story.metooCount > 0) ...[
                    const SizedBox(height: 20),
                    _MetooSummary(count: story.metooCount, notes: story.metooNotes, palette: palette, l10n: l10n),
                  ],

                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final AppPalette palette;
  const _Badge({required this.label, required this.color, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: palette.surfaceMuted, borderRadius: BorderRadius.circular(100)),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 11, height: 1.2, fontWeight: FontWeight.w600, letterSpacing: 0.44, color: color),
      ),
    );
  }
}

/// What the author sees of "Bende de oldu": how many readers found
/// themselves in the story and which notes they left, never who.
class _MetooSummary extends StatelessWidget {
  final int count;
  final Map<String, int> notes;
  final AppPalette palette;
  final AppLocalizations l10n;

  const _MetooSummary({required this.count, required this.notes, required this.palette, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final noted = [for (final key in metooNotes) if ((notes[key] ?? 0) > 0) key];

    return GlassSurface(
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🫂', style: TextStyle(fontSize: 22)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(l10n.metooOwnCount(count),
                    style: AppTypography.label.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          if (noted.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final key in noted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
                    decoration: BoxDecoration(color: palette.accentSoft, borderRadius: BorderRadius.circular(100)),
                    child: Text(
                      '${metooNoteEmoji(key)}  ${metooNoteLabel(l10n, key)} · ${notes[key]}',
                      style: AppTypography.caption.copyWith(color: palette.accent, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 10),
          Text(l10n.metooOwnPrivacy,
              style: AppTypography.caption.copyWith(color: palette.textTertiary, height: 1.4)),
        ],
      ),
    );
  }
}
