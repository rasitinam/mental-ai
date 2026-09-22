import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/components.dart';
import '../../../app/theme/glass.dart';
import '../../../core/network/error_messages.dart';
import '../../../l10n/app_localizations.dart';
import '../data/memory_api.dart';

/// "Hearth ne biliyor" — what Hearth has quietly picked up from someone's own
/// entries (mood notes, journal, their side of chat) and carries into later
/// answers so it doesn't ask the same things again. Read-only content with
/// two controls: pause it, or clear it outright — this is a mental-health
/// app, so what it remembers about a person has to stay visibly theirs to
/// see and undo, not a black box.
class PersonMemoryScreen extends ConsumerStatefulWidget {
  const PersonMemoryScreen({super.key});

  @override
  ConsumerState<PersonMemoryScreen> createState() => _PersonMemoryScreenState();
}

class _PersonMemoryScreenState extends ConsumerState<PersonMemoryScreen> {
  bool _busy = false;

  Future<void> _toggle(bool enabled) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await ref.read(memoryApiProvider).setEnabled(enabled);
      ref.invalidate(personMemoryProvider);
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.commonError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clear() async {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: palette.canvasTop,
        title: Text(l10n.memoryClearTitle, style: AppTypography.headline.copyWith(color: palette.textPrimary)),
        content: Text(l10n.memoryClearBody,
            style: AppTypography.subheadline.copyWith(color: palette.textSecondary, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.commonCancel, style: TextStyle(color: palette.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.memoryClearCta, style: TextStyle(color: palette.warning, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _busy = true);
    try {
      await ref.read(memoryApiProvider).clear();
      ref.invalidate(personMemoryProvider);
      messenger.showSnackBar(SnackBar(content: Text(l10n.memoryCleared)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.commonError)));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  IconData _iconFor(String kind) => switch (kind) {
        'theme' => Icons.repeat_rounded,
        'trigger' => Icons.bolt_outlined,
        'helps' => Icons.spa_outlined,
        'context' => Icons.info_outline_rounded,
        'goal' => Icons.flag_outlined,
        _ => Icons.circle_outlined,
      };

  String _labelFor(AppLocalizations l10n, String kind) => switch (kind) {
        'theme' => l10n.memoryKindTheme,
        'trigger' => l10n.memoryKindTrigger,
        'helps' => l10n.memoryKindHelps,
        'context' => l10n.memoryKindContext,
        'goal' => l10n.memoryKindGoal,
        _ => l10n.memoryKindTheme,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final memory = ref.watch(personMemoryProvider);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 12, 22, bottomClearance(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SquareIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(l10n.memoryTitle,
                        style: AppTypography.title3.copyWith(color: palette.textPrimary)),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(l10n.memoryIntro,
                  style: AppTypography.subheadline.copyWith(color: palette.textSecondary, height: 1.5)),
              const SizedBox(height: 20),
              Expanded(
                child: memory.when(
                  loading: () => Center(child: CircularProgressIndicator(color: palette.accent)),
                  error: (error, _) => Center(
                    child: Text(friendlyErrorMessage(l10n, error),
                        style: AppTypography.subheadline.copyWith(color: palette.warning)),
                  ),
                  data: (data) => ListView(
                    children: [
                      GlassSurface(
                        radius: 18,
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(l10n.memoryToggleLabel,
                                      style: AppTypography.label.copyWith(color: palette.textPrimary)),
                                  const SizedBox(height: 3),
                                  Text(
                                    data.enabled ? l10n.memoryToggleOnBody : l10n.memoryToggleOffBody,
                                    style: AppTypography.footnote.copyWith(color: palette.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            AppToggle(
                              value: data.enabled,
                              semanticLabel: l10n.memoryToggleLabel,
                              onChanged: _busy ? null : _toggle,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (!data.enabled) ...[
                        Text(l10n.memoryPausedNote,
                            style: AppTypography.footnote.copyWith(color: palette.textTertiary, height: 1.5)),
                      ] else if (data.items.isEmpty) ...[
                        Text(l10n.memoryEmpty,
                            style: AppTypography.subheadline.copyWith(color: palette.textSecondary, height: 1.5)),
                      ] else ...[
                        for (final item in data.items) ...[
                          GlassSurface(
                            radius: 16,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(_iconFor(item.kind), size: 18, color: palette.accent),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _labelFor(l10n, item.kind),
                                        style: AppTypography.caption.copyWith(
                                          color: palette.textTertiary,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(item.text,
                                          style: AppTypography.subheadline
                                              .copyWith(color: palette.textPrimary, height: 1.4)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                        const SizedBox(height: 10),
                        Center(
                          child: TextButton(
                            onPressed: _busy ? null : _clear,
                            child: Text(l10n.memoryClearCta,
                                style: AppTypography.footnote
                                    .copyWith(color: palette.warning, fontWeight: FontWeight.w600)),
                          ),
                        ),
                      ],
                    ],
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
