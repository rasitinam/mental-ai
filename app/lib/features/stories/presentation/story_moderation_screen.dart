import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/layout/bottom_clearance.dart';
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
                  const SizedBox(width: 14),
                  Text(l10n.storiesModerationTitle,
                      style: AppTypography.title3.copyWith(color: palette.textPrimary)),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 12),
              child: _Segmented(
                left: l10n.storiesModerationQueueTab(state.pending.length),
                right: l10n.storiesModerationReportsTab(state.reports.length),
                rightSelected: _showReports,
                palette: palette,
                onSelect: (reports) => setState(() => _showReports = reports),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                color: palette.accent,
                onRefresh: controller.load,
                child: state.loading
                    ? ListView(children: [
                        const SizedBox(height: 100),
                        Center(child: CircularProgressIndicator(color: palette.accent)),
                      ])
                    : _showReports
                        ? _ReportsList(
                            reports: state.reports,
                            processing: state.processing,
                            palette: palette,
                            l10n: l10n,
                            controller: controller,
                          )
                        : _PendingList(
                            pending: state.pending,
                            processing: state.processing,
                            palette: palette,
                            l10n: l10n,
                            controller: controller,
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Segmented extends StatelessWidget {
  final String left;
  final String right;
  final bool rightSelected;
  final AppPalette palette;
  final ValueChanged<bool> onSelect;

  const _Segmented({
    required this.left,
    required this.right,
    required this.rightSelected,
    required this.palette,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: palette.surfaceMuted,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _half(left, !rightSelected, () => onSelect(false)),
          _half(right, rightSelected, () => onSelect(true)),
        ],
      ),
    );
  }

  Widget _half(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: Material(
        color: selected ? palette.glassFill : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Center(
            child: Text(
              label,
              style: AppTypography.footnote.copyWith(
                fontSize: 13.5,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? palette.textPrimary : palette.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// One submission, with whatever the moderator needs to judge it: who
/// wrote it, when, whether the crisis screen flagged it, and — when a
/// reader sent it back — what they said about it.
class _ReviewCard extends StatelessWidget {
  final AdminStoryView story;
  final String? note;
  final bool busy;
  final String approveLabel;
  final AppPalette palette;
  final AppLocalizations l10n;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ReviewCard({
    required this.story,
    required this.note,
    required this.busy,
    required this.approveLabel,
    required this.palette,
    required this.l10n,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 18,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(story.handle,
                    style: AppTypography.footnote.copyWith(
                        color: palette.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              if (story.crisisFlag)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: palette.warningSoft,
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    l10n.storiesModerationCrisisFlag.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.44,
                      color: palette.warning,
                    ),
                  ),
                )
              else
                Text(
                  DateFormat.MMMd(Localizations.localeOf(context).languageCode)
                      .add_Hm()
                      .format(story.createdAt),
                  style: AppTypography.caption.copyWith(color: palette.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(story.body,
              style: AppTypography.subheadline
                  .copyWith(color: palette.textPrimary, height: 1.6)),
          if (note != null && note!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: palette.surfaceMuted,
                borderRadius: BorderRadius.circular(12),
              ),
              child: RichText(
                text: TextSpan(
                  style: AppTypography.footnote.copyWith(color: palette.textSecondary),
                  children: [
                    TextSpan(
                      text: '${l10n.storiesModerationReporterNote} ',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: palette.textPrimary),
                    ),
                    TextSpan(text: note),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  label: l10n.storiesModerationReject,
                  filled: false,
                  palette: palette,
                  onTap: busy ? null : onReject,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionButton(
                  label: approveLabel,
                  filled: true,
                  busy: busy,
                  palette: palette,
                  onTap: busy ? null : onApprove,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final bool filled;
  final bool busy;
  final AppPalette palette;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.label,
    required this.filled,
    required this.palette,
    required this.onTap,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? palette.accent : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          decoration: filled
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.warning.withValues(alpha: 0.45)),
                ),
          child: busy
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(
                  label,
                  style: AppTypography.label.copyWith(
                    fontSize: 14,
                    fontWeight: filled ? FontWeight.w600 : FontWeight.w500,
                    color: filled ? Colors.white : palette.warning,
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
        padding: const EdgeInsets.fromLTRB(28, 50, 28, 0),
        children: [
          Icon(Icons.task_alt_rounded, size: 28, color: palette.accent),
          const SizedBox(height: 14),
          Text(l10n.storiesModerationEmpty,
              textAlign: TextAlign.center,
              style: AppTypography.headline.copyWith(color: palette.textPrimary, fontSize: 17)),
        ],
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(22, 0, 22, bottomClearance(context)),
      itemCount: pending.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ReviewCard(
          story: pending[i],
          note: null,
          busy: processing.contains(pending[i].id),
          approveLabel: l10n.storiesModerationApprove,
          palette: palette,
          l10n: l10n,
          onApprove: () => controller.approve(pending[i].id),
          onReject: () => controller.reject(pending[i].id),
        ),
      ),
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
        padding: const EdgeInsets.fromLTRB(28, 50, 28, 0),
        children: [
          Icon(Icons.flag_outlined, size: 28, color: palette.accent),
          const SizedBox(height: 14),
          Text(l10n.storiesModerationNoReports,
              textAlign: TextAlign.center,
              style: AppTypography.headline.copyWith(color: palette.textPrimary, fontSize: 17)),
        ],
      );
    }

    return ListView.builder(
      padding: EdgeInsets.fromLTRB(22, 0, 22, bottomClearance(context)),
      itemCount: reports.length,
      itemBuilder: (context, i) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: _ReviewCard(
          story: reports[i].story,
          note: reports[i].note,
          busy: processing.contains(reports[i].story.id),
          approveLabel: l10n.storiesModerationKeep,
          palette: palette,
          l10n: l10n,
          onApprove: () => controller.approve(reports[i].story.id),
          onReject: () => controller.reject(reports[i].story.id),
        ),
      ),
    );
  }
}
