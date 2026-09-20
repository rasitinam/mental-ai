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
