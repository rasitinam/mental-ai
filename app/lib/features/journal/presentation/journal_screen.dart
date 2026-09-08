import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/widgets/countdown_text.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/journal_entry.dart';
import 'journal_controller.dart';

/// One entry per day (enforced by the backend), plus the archive of every
/// past entry by date — a journal you can't read back is just a form.
class JournalScreen extends ConsumerStatefulWidget {
  const JournalScreen({super.key});

  @override
  ConsumerState<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends ConsumerState<JournalScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatRemaining(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours > 0) return '$hours sa $minutes dk';
    return '$minutes dk ${d.inSeconds.remainder(60)} sn';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(journalControllerProvider);
    final journalController = ref.read(journalControllerProvider.notifier);
    final palette = AppPalette.of(context);
    final onCooldown = state.isOnCooldown;

    ref.listen(journalControllerProvider, (prev, next) {
      if (next.submitted && prev?.submitted != true) {
        _controller.clear();
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.journalSaved)));
        journalController.acknowledgeSubmitted();
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navJournal)),
      body: RefreshIndicator(
        color: palette.accent,
        onRefresh: journalController.load,
        // The composer and the labels are a fixed handful of widgets, but
        // the archive below them grows by one card a day forever, so it is
        // built lazily in its own sliver rather than in one eager list.
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              sliver: SliverList.list(
                children: [
                  if (onCooldown)
                    _CooldownCard(
                      until: state.cooldownUntil!,
                      format: _formatRemaining,
                      palette: palette,
                      // One rebuild when the cooldown lapses, to swap the
                      // card back for the composer.
                      onFinished: () => setState(() {}),
                    )
                  else ...[
                    GlassSurface(
                      radius: 26,
                      padding: const EdgeInsets.all(4),
                      child: TextField(
                        controller: _controller,
                        maxLines: 8,
                        minLines: 6,
                        textAlignVertical: TextAlignVertical.top,
                        style: AppTypography.body.copyWith(color: palette.textPrimary),
                        cursorColor: palette.accent,
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.all(18),
                          hintText: l10n.journalHint,
                          hintStyle: AppTypography.body.copyWith(color: palette.textTertiary),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(state.error!, style: TextStyle(color: palette.warning)),
                      ),
                    AppPrimaryButton(
                      label: l10n.commonSave,
                      loading: state.submitting,
                      onPressed: () => journalController.submit(_controller.text),
                    ),
                  ],
                  const SizedBox(height: 28),
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 10),
                    child: Text(
                      l10n.journalPast,
                      style: AppTypography.caption.copyWith(
                        color: palette.textTertiary,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  if (state.loading)
                    Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: Center(child: CircularProgressIndicator(color: palette.accent)),
                    )
                  else if (state.entries.isEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        l10n.journalEmpty,
                        style: AppTypography.subheadline.copyWith(color: palette.textTertiary),
                      ),
                    ),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 140),
              sliver: SliverList.builder(
                itemCount: state.loading ? 0 : state.entries.length,
                itemBuilder: (context, i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _JournalEntryCard(entry: state.entries[i], palette: palette),
                ),
              ),
            ),
          ],
        ),
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
      radius: 26,
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 30, color: palette.accent),
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
            style: AppTypography.footnote.copyWith(color: palette.textTertiary),
          ),
        ],
      ),
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
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 14, color: palette.accent),
              const SizedBox(width: 8),
              Text(
                DateFormat.yMMMMd().add_Hm().format(entry.createdAt),
                style: AppTypography.caption.copyWith(color: palette.textTertiary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(entry.body, style: AppTypography.subheadline.copyWith(color: palette.textPrimary)),
        ],
      ),
    );
  }
}
