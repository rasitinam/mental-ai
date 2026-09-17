import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_typography.dart';
import '../../app/theme/glass.dart';

/// A compact "Türkçe / English" toggle, each language named in itself so
/// someone who can't read the current one can still find their own. Used
/// wherever someone might need to pick a language before they're signed
/// in — the privacy summary and the login/register screen — so the whole
/// app never traps anyone in a language they can't read.
class LanguageSwitch extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const LanguageSwitch({super.key, required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return GlassSurface(
      radius: 14,
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final (code, label) in const [('tr', 'Türkçe'), ('en', 'English')])
            Semantics(
              button: true,
              selected: code == selected,
              child: Material(
                color: code == selected ? palette.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(11),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => onChanged(code),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                    child: Text(
                      label,
                      style: AppTypography.label.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: code == selected ? palette.onAccent : palette.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
