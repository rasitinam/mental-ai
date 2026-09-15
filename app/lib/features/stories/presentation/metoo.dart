import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/components.dart';
import '../../../app/theme/glass.dart';
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

/// Two overlapping circles — two people, one shape between them.
class MetooGlyph extends StatelessWidget {
  final double size;
  final Color color;
  const MetooGlyph({super.key, this.size = 22, required this.color});

  @override
  Widget build(BuildContext context) =>
      CustomPaint(size: Size.square(size), painter: _MetooGlyphPainter(color));
}

class _MetooGlyphPainter extends CustomPainter {
  final Color color;
  _MetooGlyphPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08;
    final r = size.width * 0.23;
    canvas.drawCircle(Offset(size.width * 0.375, size.height / 2), r, paint);
    canvas.drawCircle(Offset(size.width * 0.625, size.height / 2), r, paint);
  }

  @override
  bool shouldRepaint(_MetooGlyphPainter old) => old.color != color;
}

/// A full-width button under a story's reactions. Separate from the three
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
    final foreground = active ? palette.onAccent : palette.onTint;

    final String trailing;
    if (active) {
      trailing = count > 1 ? l10n.metooWithYou(count - 1) : l10n.metooYouSaidIt;
    } else {
      trailing = count > 0 ? l10n.metooCount(count) : '';
    }

    return Semantics(
      button: true,
      selected: active,
      child: Material(
        color: active ? palette.accent : palette.peach,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                active
                    ? Icon(Icons.check_rounded, size: 20, color: foreground)
                    : MetooGlyph(size: 22, color: foreground),
                const SizedBox(width: 10),
                Text(
                  l10n.metooButton,
                  style: AppTypography.label.copyWith(color: foreground, fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    trailing,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: AppTypography.subheadline.copyWith(
                      color: foreground.withValues(alpha: 0.75),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
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
    builder: (sheetContext) {
      var selected = metooNotes.first;

      return StatefulBuilder(
        builder: (sheetContext, setState) {
          final palette = AppPalette.of(sheetContext);
          final l10n = AppLocalizations.of(sheetContext)!;

          return SheetFrame(
            children: [
              Row(
                children: [
                  MetooGlyph(size: 17, color: palette.textSecondary),
                  const SizedBox(width: 7),
                  SectionLabel(l10n.metooButton),
                ],
              ),
              const SizedBox(height: 6),
              Text(l10n.metooSheetTitle,
                  style: AppTypography.title3.copyWith(color: palette.textPrimary, fontSize: 23, height: 1.12)),
              const SizedBox(height: 8),
              Text(l10n.metooSheetBody,
                  style: AppTypography.subheadline.copyWith(color: palette.textSecondary, fontSize: 15.5)),
              const SizedBox(height: 14),
              for (final note in metooNotes) ...[
                _NoteOption(
                  label: metooNoteLabel(l10n, note),
                  selected: selected == note,
                  onTap: () => setState(() => selected = note),
                ),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 6),
              AppPrimaryButton(
                label: l10n.storiesSubmit,
                onPressed: () => Navigator.of(sheetContext).pop(selected),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.of(sheetContext).pop(metooNoNote),
                child: Text(l10n.metooJustMark,
                    style: AppTypography.label.copyWith(color: palette.textSecondary, fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      );
    },
  );
}

class _NoteOption extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NoteOption({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Semantics(
      inMutuallyExclusiveGroup: true,
      checked: selected,
      button: true,
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: selected ? palette.textPrimary : palette.separator, width: selected ? 2 : 1.5),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minHeight: 52),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? palette.textPrimary : palette.textTertiary,
                      width: selected ? 7 : 2,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(label, style: AppTypography.label.copyWith(color: palette.textPrimary, fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
