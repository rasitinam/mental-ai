import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
import 'profile_controller.dart';

/// Account details that shape what the app generates: the address it signs
/// in with, the language everything is written in, and an age — which is
/// here because the same diagnosis describes a very different life at 16
/// than at 45, and without it the answers default to generic adult advice.
class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _birthYear = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _birthYear.dispose();
    super.dispose();
  }

  Future<void> _saveBirthYear(AppLocalizations l10n) async {
    final raw = _birthYear.text.trim();
    if (raw.isEmpty) return;

    final year = int.tryParse(raw);
    final thisYear = DateTime.now().year;
    if (year == null || year < thisYear - 120 || year > thisYear) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.profileInvalidYear)),
      );
      return;
    }

    await ref.read(profileControllerProvider.notifier).savePreferences(birthYear: year);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(profileControllerProvider);
    final controller = ref.read(profileControllerProvider.notifier);
    final palette = AppPalette.of(context);

    // Prefilled once, not on every rebuild, so it doesn't fight the cursor
    // while someone is typing.
    if (!_prefilled && state.birthYear != null) {
      _birthYear.text = state.birthYear.toString();
      _prefilled = true;
    }

    ref.listen(profileControllerProvider, (previous, next) {
      if (next.saved && previous?.saved != true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.profileSaved)),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileTitle)),
      body: state.loading
          ? Center(child: CircularProgressIndicator(color: palette.accent))
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
              children: [
                GlassSurface(
                  radius: 22,
                  child: Row(
                    children: [
                      Icon(Icons.alternate_email_rounded, size: 20, color: palette.accent),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.profileEmail,
                                style: AppTypography.footnote
                                    .copyWith(color: palette.textTertiary)),
                            const SizedBox(height: 3),
                            Text(state.email ?? '—',
                                style: AppTypography.headline
                                    .copyWith(color: palette.textPrimary)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(l10n.profileLanguage.toUpperCase(),
                    style: AppTypography.caption
                        .copyWith(color: palette.textTertiary, letterSpacing: 0.6)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _LanguageOption(
                        label: l10n.profileLanguageTurkish,
                        code: 'tr',
                        selected: state.language == 'tr',
                        palette: palette,
                        onTap: () => controller.savePreferences(language: 'tr'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _LanguageOption(
                        label: l10n.profileLanguageEnglish,
                        code: 'en',
                        selected: state.language == 'en',
                        palette: palette,
                        onTap: () => controller.savePreferences(language: 'en'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(l10n.profileBirthYear.toUpperCase(),
                    style: AppTypography.caption
                        .copyWith(color: palette.textTertiary, letterSpacing: 0.6)),
                const SizedBox(height: 10),
                GlassSurface(
                  radius: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _birthYear,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              style: AppTypography.body.copyWith(color: palette.textPrimary),
                              decoration: InputDecoration(
                                border: InputBorder.none,
                                isDense: true,
                                hintText: l10n.profileBirthYearHint,
                                hintStyle:
                                    AppTypography.body.copyWith(color: palette.textTertiary),
                              ),
                              onSubmitted: (_) => _saveBirthYear(l10n),
                            ),
                          ),
                          if (state.age != null)
                            Text(l10n.profileAgeValue(state.age!),
                                style: AppTypography.footnote.copyWith(color: palette.accent)),
                          const SizedBox(width: 10),
                          IconButton(
                            icon: Icon(Icons.check_rounded, color: palette.accent),
                            onPressed: state.saving ? null : () => _saveBirthYear(l10n),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(l10n.profileAgeWhy,
                          style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                GlassSurface(
                  radius: 22,
                  padding: EdgeInsets.zero,
                  child: InkWell(
                    onTap: () => context.go('/settings/diagnoses'),
                    borderRadius: BorderRadius.circular(22),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.assignment_ind_outlined, size: 20, color: palette.accent),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(l10n.profileDiagnoses,
                                style: AppTypography.headline
                                    .copyWith(color: palette.textPrimary)),
                          ),
                          Text('${state.diagnoses.length}',
                              style: AppTypography.footnote.copyWith(color: palette.accent)),
                          const SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded, size: 20, color: palette.textTertiary),
                        ],
                      ),
                    ),
                  ),
                ),
                if (state.error != null) ...[
                  const SizedBox(height: 16),
                  Text(state.error!, style: TextStyle(color: palette.warning)),
                ],
              ],
            ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String label;
  final String code;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.label,
    required this.code,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? palette.accent : palette.glassFill,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: selected ? palette.accent : palette.glassBorder),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                code.toUpperCase(),
                style: AppTypography.caption.copyWith(
                  color: selected ? palette.canvasBottom : palette.textTertiary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.headline.copyWith(
                  color: selected ? palette.canvasBottom : palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
