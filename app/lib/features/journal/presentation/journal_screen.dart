import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/network/error_messages.dart';
import '../../../core/onboarding/first_run.dart';
import '../../../core/storage/local_prefs.dart';
import '../../../core/widgets/countdown_text.dart';
import '../../../core/widgets/skeleton.dart';
import '../../../l10n/app_localizations.dart';
import '../../streak/data/streak_api.dart';
import '../domain/journal_entry.dart';
import 'journal_controller.dart';

/// One entry per day (enforced by the backend), plus the archive of every
/// past entry by date — a journal you can't read back is just a form.
class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

/// Where an unsent entry is parked between app launches. Local only —
/// a draft is by definition the part someone hasn't decided to keep.
const _draftKey = 'mental_ai.journal_draft';

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    final draft = ref.read(sharedPreferencesProvider).getString(_draftKey);
    if (draft != null) _controller.text = draft;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatRemaining(AppLocalizations l10n, Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '$hours${l10n.timeUnitHour} $minutes${l10n.timeUnitMinute}';
    return '$minutes${l10n.timeUnitMinute} ${d.inSeconds.remainder(60)}${l10n.timeUnitSecond}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(journalControllerProvider);
    final journalController = ref.read(journalControllerProvider.notifier);
    final palette = AppPalette.of(context);
    final onCooldown = state.isOnCooldown;
    final streak = ref.watch(streakProvider).valueOrNull;

    ref.listen(journalControllerProvider, (prev, next) {
      if (next.submitted && prev?.submitted != true) {
        _controller.clear();
        ref.read(sharedPreferencesProvider).remove(_draftKey);
        ref.invalidate(streakProvider);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.journalSaved)));
        journalController.acknowledgeSubmitted();
        celebrateFirst(
          context,
          ref,
          key: FirstRun.firstJournal,
          icon: Icons.menu_book_rounded,
          title: l10n.milestoneFirstJournalTitle,
          body: l10n.milestoneFirstJournalBody,
        );
      }
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: palette.accent,
          onRefresh: journalController.load,
          // The composer and the labels are a fixed handful of widgets, but
          // the archive below them grows by one card a day forever, so it is
          // built lazily in its own sliver rather than in one eager list.
          child: CustomScrollView(
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
                sliver: SliverList.list(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(l10n.journalPrompt,
                                  style:
                                      AppTypography.title2.copyWith(color: palette.textPrimary)),
                              const SizedBox(height: 5),
                              Text(l10n.journalPromptNote,
                                  style: AppTypography.footnote
                                      .copyWith(color: palette.textSecondary)),
                            ],
                          ),
                        ),
                        if (streak != null && streak.current > 0) ...[
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text('${streak.current}',
                                  style: AppTypography.headline
                                      .copyWith(color: palette.accent, fontSize: 18)),
                              const SizedBox(height: 2),
                              SectionLabel(l10n.streakJournalLabel),
                            ],
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),
                    FeatureIntroCard(
                      introKey: FirstRun.journalIntro,
                      icon: Icons.menu_book_rounded,
                      title: l10n.introJournalTitle,
                      body: l10n.introJournalBody,
                    ),
                    if (onCooldown)
                      _CooldownCard(
                        until: state.cooldownUntil!,
                        format: (remaining) => _formatRemaining(l10n, remaining),
                        palette: palette,
                        // One rebuild when the cooldown lapses, to swap the
                        // card back for the composer.
                        onFinished: () => setState(() {}),
                      )
                    else ...[
                      _Composer(
                        controller: _controller,
                        palette: palette,
                        hint: l10n.journalHint,
                        onChanged: (value) =>
                            ref.read(sharedPreferencesProvider).setString(_draftKey, value),
                        footer: (value) => Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(l10n.journalCharCount(value.length),
                                style: AppTypography.caption
                                    .copyWith(color: palette.textSecondary)),
                            if (value.isNotEmpty)
                              Text(l10n.journalDraftSaved,
                                  style: AppTypography.caption
                                      .copyWith(color: palette.textSecondary)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (state.error != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(friendlyErrorMessage(l10n, state.error!),
                              style: TextStyle(color: palette.warning)),
                        ),
                      AppPrimaryButton(
                        label: l10n.commonSave,
                        loading: state.submitting,
                        onPressed: () => journalController.submit(_controller.text),
                      ),
                    ],
                    const SizedBox(height: 26),
                    SectionLabel(l10n.journalPast),
                    const SizedBox(height: 10),
                    if (state.loading)
                      const _JournalEntrySkeleton()
                    else if (state.entries.isEmpty)
                      Text(
                        l10n.journalEmpty,
                        style: AppTypography.footnote.copyWith(color: palette.textSecondary),
                      ),
                  ],
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(22, 0, 22, bottomClearance(context)),
                sliver: SliverList.builder(
                  itemCount: state.loading ? 0 : state.entries.length,
                  itemBuilder: (context, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _JournalEntryCard(entry: state.entries[i], palette: palette),
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

/// The writing surface: a card outlined in the accent so it reads as the
/// one thing on the screen waiting for input, with the counter and draft
/// state pinned to its floor.
class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final AppPalette palette;
  final String hint;
  final ValueChanged<String> onChanged;
  final Widget Function(String value) footer;

  const _Composer({
    required this.controller,
    required this.palette,
    required this.hint,
    required this.onChanged,
    required this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 170),
      decoration: BoxDecoration(
        color: palette.glassFill,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: palette.accent, width: 2),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: controller,
            maxLines: null,
            minLines: 5,
            onChanged: onChanged,
            textAlignVertical: TextAlignVertical.top,
            style: AppTypography.body.copyWith(color: palette.textPrimary),
            cursorColor: palette.accent,
            decoration: InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: hint,
              hintStyle: AppTypography.body.copyWith(color: palette.textTertiary),
              border: InputBorder.none,
            ),
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) => footer(value.text),
          ),
        ],
      ),
    );
  }
}

class _CooldownCard extends StatelessWidget {
  final DateTime until;
  final String Function(Duration) format;
  final AppPalette palette;
  final VoidCallback onFinished;

  const _CooldownCard({
    required this.until,
    required this.format,
    required this.palette,
    required this.onFinished,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return GlassSurface(
      radius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 28, color: palette.accent),
          const SizedBox(height: 12),
          Text(
            l10n.journalDoneToday,
            style: AppTypography.headline.copyWith(color: palette.textPrimary),
          ),
          const SizedBox(height: 6),
          CountdownText(
            until: until,
            onFinished: onFinished,
            format: (remaining) => l10n.journalNextIn(format(remaining)),
            textAlign: TextAlign.center,
            style: AppTypography.footnote.copyWith(color: palette.textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Stands in for the archive list while it loads — shaped like
/// [_JournalEntryCard] itself (a date line over a couple of body lines) so
/// the list doesn't visibly jump once the real entries arrive.
class _JournalEntrySkeleton extends StatelessWidget {
  const _JournalEntrySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < 3; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlassSurface(
              radius: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(width: 110, height: 11),
                  SizedBox(height: 10),
                  SkeletonBox(height: 13),
                  SizedBox(height: 7),
                  SkeletonBox(width: 220, height: 13),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _JournalEntryCard extends StatelessWidget {
  final JournalEntry entry;
  final AppPalette palette;
  const _JournalEntryCard({required this.entry, required this.palette});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat.yMMMMd(Localizations.localeOf(context).languageCode)
                .add_Hm()
                .format(entry.createdAt),
            style: AppTypography.caption.copyWith(color: palette.textSecondary),
          ),
          const SizedBox(height: 6),
          Text(entry.body, style: AppTypography.subheadline.copyWith(color: palette.textPrimary)),
        ],
      ),
    );
  }
}
