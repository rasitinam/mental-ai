import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/life_story.dart';
import 'moderation_controller.dart';

/// Admin-only queue: stories waiting for a first decision, and stories a
/// reader flagged after the fact. The route itself isn't hidden from a
/// non-admin who guesses the URL, but every request it makes fails
/// server-side (`require_admin` in `apps/server/src/routes/stories.rs`)
/// — this screen is a convenience, not the actual access control.
class StoryModerationScreen extends ConsumerStatefulWidget {
  const StoryModerationScreen({super.key});

  @override
  ConsumerState<StoryModerationScreen> createState() => _StoryModerationScreenState();
}

class _StoryModerationScreenState extends ConsumerState<StoryModerationScreen> {
  bool _showReports = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final state = ref.watch(moderationControllerProvider);
    final controller = ref.read(moderationControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.storiesModerationTitle)),
      body: RefreshIndicator(
        color: palette.accent,
        onRefresh: controller.load,
        child: state.loading
            ? ListView(children: [const SizedBox(height: 120), Center(child: CircularProgressIndicator(color: palette.accent))])
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SegmentButton(
                            label: l10n.storiesModerationQueueTab(state.pending.length),
                            selected: !_showReports,
                            palette: palette,
                            onTap: () => setState(() => _showReports = false),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _SegmentButton(
                            label: l10n.storiesModerationReportsTab(state.reports.length),
                            selected: _showReports,
                            palette: palette,
                            onTap: () => setState(() => _showReports = true),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _showReports
                        ? _ReportsList(reports: state.reports, processing: state.processing, palette: palette, l10n: l10n, controller: controller)
                        : _PendingList(pending: state.pending, processing: state.processing, palette: palette, l10n: l10n, controller: controller),
                  ),
                ],
              ),
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  final String label;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  const _SegmentButton({required this.label, required this.selected, required this.palette, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? palette.accent : palette.glassFill,
      borderRadius: BorderRadius.circular(100),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Center(
            child: Text(
              label,
              style: AppTypography.subheadline.copyWith(
                color: selected ? palette.canvasBottom : palette.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PendingList extends StatelessWidget {
  final List<AdminStoryView> pending;
  final Set<String> processing;
  final AppPalette palette;
  final AppLocalizations l10n;
  final ModerationController controller;

  const _PendingList({
    required this.pending,
    required this.processing,
    required this.palette,
    required this.l10n,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (pending.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(28, 60, 28, 0),
        children: [
          Icon(Icons.task_alt_rounded, size: 30, color: palette.accent),
          const SizedBox(height: 14),
          Text(l10n.storiesModerationEmpty, textAlign: TextAlign.center, style: AppTypography.headline.copyWith(color: palette.textPrimary)),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
      itemCount: pending.length,
      itemBuilder: (context, i) {
        final story = pending[i];
        final busy = processing.contains(story.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GlassSurface(
            radius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(story.handle, style: AppTypography.subheadline.copyWith(color: palette.textSecondary, fontWeight: FontWeight.w600)),
                    ),
                    if (story.crisisFlag)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: palette.warningSoft, borderRadius: BorderRadius.circular(100)),
                        child: Text(l10n.storiesModerationCrisisFlag, style: AppTypography.caption.copyWith(color: palette.warning)),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(story.body, style: AppTypography.body.copyWith(color: palette.textPrimary)),
                const SizedBox(height: 4),
                Text(
                  DateFormat.yMMMd(Localizations.localeOf(context).languageCode).format(story.createdAt),
                  style: AppTypography.caption.copyWith(color: palette.textTertiary),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy ? null : () => controller.reject(story.id),
                        style: OutlinedButton.styleFrom(foregroundColor: palette.warning, side: BorderSide(color: palette.warning)),
                        child: Text(l10n.storiesModerationReject),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: busy ? null : () => controller.approve(story.id),
                        style: FilledButton.styleFrom(backgroundColor: palette.accent),
                        child: busy
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(l10n.storiesModerationApprove),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReportsList extends StatelessWidget {
  final List<ReportedStory> reports;
  final Set<String> processing;
  final AppPalette palette;
  final AppLocalizations l10n;
  final ModerationController controller;

  const _ReportsList({
    required this.reports,
    required this.processing,
    required this.palette,
    required this.l10n,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    if (reports.isEmpty) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(28, 60, 28, 0),
        children: [
          Icon(Icons.flag_outlined, size: 30, color: palette.accent),
          const SizedBox(height: 14),
          Text(l10n.storiesModerationNoReports, textAlign: TextAlign.center, style: AppTypography.headline.copyWith(color: palette.textPrimary)),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
      itemCount: reports.length,
      itemBuilder: (context, i) {
        final report = reports[i];
        final busy = processing.contains(report.story.id);
        return Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: GlassSurface(
            radius: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(report.story.handle, style: AppTypography.subheadline.copyWith(color: palette.textSecondary, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(report.story.body, style: AppTypography.body.copyWith(color: palette.textPrimary)),
                if (report.note != null && report.note!.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: palette.warningSoft, borderRadius: BorderRadius.circular(14)),
                    child: Text(report.note!, style: AppTypography.footnote.copyWith(color: palette.warning)),
                  ),
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: busy ? null : () => controller.reject(report.story.id),
                        style: OutlinedButton.styleFrom(foregroundColor: palette.warning, side: BorderSide(color: palette.warning)),
                        child: Text(l10n.storiesModerationReject),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: busy ? null : () => controller.approve(report.story.id),
                        style: FilledButton.styleFrom(backgroundColor: palette.accent),
                        child: busy
                            ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : Text(l10n.storiesModerationKeep),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
