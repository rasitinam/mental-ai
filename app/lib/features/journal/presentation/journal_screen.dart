import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
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
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // Drives the countdown label and re-enables the form when the cooldown
    // lapses — the actual gate is server-side.
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _ticker?.cancel();
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
    final state = ref.watch(journalControllerProvider);
    final journalController = ref.read(journalControllerProvider.notifier);
    final palette = AppPalette.of(context);
    final onCooldown = state.isOnCooldown;

    ref.listen(journalControllerProvider, (prev, next) {
      if (next.submitted && prev?.submitted != true) {
        _controller.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Günlük kaydedildi.')),
        );
        journalController.acknowledgeSubmitted();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Günlük')),
      body: RefreshIndicator(
        color: palette.accent,
        onRefresh: journalController.load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
          children: [
            if (onCooldown)
              _CooldownCard(
                remaining: _formatRemaining(state.cooldownUntil!.difference(DateTime.now())),
                palette: palette,
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
                    hintText: 'Bugün aklından ne geçti?',
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
                label: 'Kaydet',
                loading: state.submitting,
                onPressed: () => journalController.submit(_controller.text),
              ),
            ],
            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.only(left: 4, bottom: 10),
              child: Text(
                'GEÇMİŞ GÜNLÜKLER',
                style: AppTypography.caption.copyWith(color: palette.textTertiary, letterSpacing: 0.6),
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
                  'Henüz bir günlük yazmadın.',
                  style: AppTypography.subheadline.copyWith(color: palette.textTertiary),
                ),
              )
            else
              for (final entry in state.entries)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _JournalEntryCard(entry: entry, palette: palette),
                ),
          ],
        ),
      ),
    );
  }
}

class _CooldownCard extends StatelessWidget {
  final String remaining;
  final AppPalette palette;
  const _CooldownCard({required this.remaining, required this.palette});

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      radius: 26,
      child: Column(
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 30, color: palette.accent),
          const SizedBox(height: 12),
          Text(
            'Bugünkü günlüğün yazıldı',
            style: AppTypography.headline.copyWith(color: palette.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            'Sonraki giriş $remaining sonra açılıyor',
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
