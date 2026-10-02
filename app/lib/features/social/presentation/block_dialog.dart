import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../l10n/app_localizations.dart';

/// Asks before blocking someone. Blocking takes effect on both sides at once
/// (neither sees the other's stories or profile, neither can message), so it
/// gets a confirmation that also says where to undo it. Returns `true` only
/// on an explicit confirm.
Future<bool> confirmBlock(BuildContext context) async {
  final l10n = AppLocalizations.of(context)!;
  final palette = AppPalette.of(context);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.blockConfirmTitle, style: AppTypography.headline.copyWith(color: palette.textPrimary)),
      content: Text(l10n.blockConfirmBody,
          style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.commonCancel)),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.blockAction, style: TextStyle(color: palette.warning)),
        ),
      ],
    ),
  );
  return confirmed == true;
}

/// Asks for an optional note before reporting a person or a conversation.
/// Returns the note (empty when they left none), or `null` if they cancelled.
Future<String?> askReport(BuildContext context, {required String title}) async {
  final l10n = AppLocalizations.of(context)!;
  final palette = AppPalette.of(context);
  final note = TextEditingController();

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title, style: AppTypography.headline.copyWith(color: palette.textPrimary)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.reportBody, style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
          const SizedBox(height: 12),
          TextField(
            controller: note,
            maxLines: 3,
            style: AppTypography.body.copyWith(color: palette.textPrimary),
            decoration: InputDecoration(
              hintText: l10n.storiesReportNoteHint,
              hintStyle: AppTypography.body.copyWith(color: palette.textTertiary),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: Text(l10n.commonCancel)),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.reportAction, style: TextStyle(color: palette.warning)),
        ),
      ],
    ),
  );
  final text = note.text.trim();
  note.dispose();
  return confirmed == true ? text : null;
}
