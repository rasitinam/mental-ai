import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

/// The notes a reader can leave with "Bende de oldu" — must match
/// `METOO_NOTES` in `backend/crates/domain/src/life_story.rs`. A closed list
/// on purpose: see the comment there.
const metooNotes = ['yalniz_degilsin', 'ben_de_yasadim', 'tesekkurler', 'guc_yolluyorum'];

String metooNoteLabel(AppLocalizations l10n, String key) => switch (key) {
      'yalniz_degilsin' => l10n.metooNoteNotAlone,
      'ben_de_yasadim' => l10n.metooNoteSameHere,
      'tesekkurler' => l10n.metooNoteThanks,
      'guc_yolluyorum' => l10n.metooNoteStrength,
      _ => key,
    };

String metooNoteEmoji(String key) => switch (key) {
      'yalniz_degilsin' => '🤝',
      'ben_de_yasadim' => '🫂',
      'tesekkurler' => '💚',
      'guc_yolluyorum' => '✨',
      _ => '🫂',
    };

/// A full-width strip under a story's reactions. Separate from the three
/// reaction chips on purpose: those say how the story made you feel; this
/// says "this is my story too", which is a different act and can coexist
/// with any reaction.
class MetooStrip extends StatelessWidget {
  final int count;
  final bool active;
  final VoidCallback onTap;

  const MetooStrip({super.key, required this.count, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context)!;

    final String trailing;
    if (active) {
      trailing = count > 1 ? l10n.metooWithYou(count - 1) : l10n.metooYouSaidIt;
    } else {
      trailing = count > 0 ? l10n.metooCount(count) : '';
    }

    return Material(
      color: active ? palette.accentSoft : palette.surfaceMuted,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 40),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: active ? palette.accent : Colors.transparent),
          ),
          child: Row(
            children: [
              const Text('🫂', style: TextStyle(fontSize: 15)),
              const SizedBox(width: 8),
              Text(
                l10n.metooButton,
                style: AppTypography.caption.copyWith(
                  color: active ? palette.accent : palette.textPrimary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12.5,
                ),
              ),
              if (active) ...[
                const SizedBox(width: 5),
                Icon(Icons.check_rounded, size: 15, color: palette.accent),
              ],
              const Spacer(),
              if (trailing.isNotEmpty)
                Flexible(
                  child: Text(
                    trailing,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AppTypography.caption.copyWith(color: active ? palette.accent : palette.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// What the sheet resolves to: a note key, [metooNoNote] for "just mark
/// it", or `null` if it was dismissed.
const metooNoNote = '';

/// Asks whether to leave a note with "Bende de oldu". Opens on the root
/// navigator, above the tab bar.
Future<String?> showMetooSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) {
      final palette = AppPalette.of(sheetContext);
      final l10n = AppLocalizations.of(sheetContext)!;

      return Container(
        decoration: BoxDecoration(
          color: palette.canvasTop,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(22, 14, 22, 20 + MediaQuery.paddingOf(sheetContext).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: palette.separator, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('🫂', textAlign: TextAlign.center, style: TextStyle(fontSize: 34)),
            const SizedBox(height: 10),
            Text(l10n.metooSheetTitle,
                textAlign: TextAlign.center,
                style: AppTypography.title3.copyWith(color: palette.textPrimary)),
            const SizedBox(height: 8),
            Text(l10n.metooSheetBody,
                textAlign: TextAlign.center,
                style: AppTypography.footnote.copyWith(color: palette.textSecondary, height: 1.5)),
            const SizedBox(height: 18),
            for (final note in metooNotes) ...[
              Material(
                color: palette.glassFill,
                borderRadius: BorderRadius.circular(16),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(sheetContext).pop(note),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: palette.separator),
                    ),
                    child: Row(
                      children: [
                        Text(metooNoteEmoji(note), style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(metooNoteLabel(l10n, note),
                              style: AppTypography.label.copyWith(color: palette.textPrimary)),
                        ),
                        Icon(Icons.send_rounded, size: 16, color: palette.textTertiary),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => Navigator.of(sheetContext).pop(metooNoNote),
              child: Text(l10n.metooJustMark,
                  style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
            ),
          ],
        ),
      );
    },
  );
}
