import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/widgets/hearth_flame.dart';
import '../../../l10n/app_localizations.dart';
import '../domain/recap_data.dart';
import 'recap_controller.dart';

/// The five-step breakdown the daily report's own face uses, reworded here
/// as a sentence about the whole week rather than a single emoji.
String _moodHeadline(AppLocalizations l10n, double? avgValence) {
  if (avgValence == null) return l10n.recapMoodEmpty;
  if (avgValence >= 0.5) return l10n.recapMoodVeryPositive;
  if (avgValence >= 0.15) return l10n.recapMoodPositive;
  if (avgValence > -0.15) return l10n.recapMoodNeutral;
  if (avgValence > -0.5) return l10n.recapMoodMixed;
  return l10n.recapMoodHard;
}

/// A shareable weekly summary, built entirely from data already on the
/// device (mood history, the journal archive, the streak) — nothing here
/// is fetched or computed server-side. Pushed from the report screen's
/// recap card rather than a tab: it's a destination someone visits, not
/// one they live on.
class RecapScreen extends ConsumerStatefulWidget {
  const RecapScreen({super.key});

  @override
  ConsumerState<RecapScreen> createState() => _RecapScreenState();
}

class _RecapScreenState extends ConsumerState<RecapScreen> {
  final _cardKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share(AppLocalizations l10n, RecapData data) async {
    setState(() => _sharing = true);
    try {
      final boundary = _cardKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();

      final file = XFile.fromData(bytes, name: 'hearth_recap.png', mimeType: 'image/png');
      await Share.shareXFiles([file], text: l10n.recapShareText(data.checkins, data.streak));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final recap = ref.watch(recapProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SquareIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.recapTitle,
                      style: AppTypography.title2.copyWith(color: palette.textPrimary)),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: Center(
                  child: recap.when(
                    loading: () => CircularProgressIndicator(color: palette.accent),
                    error: (_, _) => Text(l10n.commonError,
                        style: AppTypography.subheadline.copyWith(color: palette.warning)),
                    data: (data) => SingleChildScrollView(
                      child: RepaintBoundary(
                        key: _cardKey,
                        child: _RecapCard(data: data, palette: palette, l10n: l10n),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              recap.maybeWhen(
                data: (data) => AppPrimaryButton(
                  label: l10n.recapShare,
                  icon: Icons.ios_share_rounded,
                  loading: _sharing,
                  onPressed: () => _share(l10n, data),
                ),
                orElse: () => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The card itself — what gets rendered to an image and shared. Kept as
/// its own opaque-background widget (rather than transparent over the
/// scaffold) since a shared PNG needs a real ground to composite onto.
class _RecapCard extends StatelessWidget {
  final RecapData data;
  final AppPalette palette;
  final AppLocalizations l10n;

  const _RecapCard({required this.data, required this.palette, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final period = '${DateFormat.MMMd(locale).format(data.periodStart)} — '
        '${DateFormat.MMMd(locale).format(data.periodEnd)}';

    return Container(
      width: 320,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: palette.glassFill,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.glassBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(shape: BoxShape.circle, color: palette.accent),
              ),
              const SizedBox(width: 8),
              Text('Hearth',
                  style: AppTypography.headline.copyWith(color: palette.textPrimary, fontSize: 15)),
              const Spacer(),
              HearthFlame(streak: data.streak, size: 28),
            ],
          ),
          const SizedBox(height: 4),
          Text(period, style: AppTypography.caption.copyWith(color: palette.textSecondary)),
          const SizedBox(height: 22),
          Text(
            _moodHeadline(l10n, data.avgValence),
            style: AppTypography.title2.copyWith(color: palette.textPrimary, fontSize: 19, height: 1.35),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(child: _Stat(value: '${data.checkins}', label: l10n.recapCheckins, palette: palette)),
              const SizedBox(width: 10),
              Expanded(
                  child:
                      _Stat(value: '${data.journalEntries}', label: l10n.recapJournalEntries, palette: palette)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                  child: _Stat(value: '${data.activeDays}/7', label: l10n.recapActiveDays, palette: palette)),
              const SizedBox(width: 10),
              Expanded(
                  child: _Stat(
                      value: '${data.streak}', label: '${l10n.streakLabel} (${l10n.streakDays})', palette: palette)),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final AppPalette palette;
  const _Stat({required this.value, required this.label, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(color: palette.surfaceMuted, borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: AppTypography.title3.copyWith(color: palette.textPrimary, fontSize: 20)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.caption.copyWith(color: palette.textSecondary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}
