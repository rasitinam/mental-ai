import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/network/error_messages.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../data/profile_api.dart';
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
  final _displayName = TextEditingController();
  final _birthYear = TextEditingController();
  bool _prefilled = false;

  @override
  void dispose() {
    _displayName.dispose();
    _birthYear.dispose();
    super.dispose();
  }

  Future<void> _saveDisplayName() async {
    final raw = _displayName.text.trim();
    if (raw.isEmpty) return;

    await ref.read(profileControllerProvider.notifier).savePreferences(displayName: raw);
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
    if (!_prefilled && state.displayName.isNotEmpty) {
      _displayName.text = state.displayName;
      if (state.birthYear != null) _birthYear.text = state.birthYear.toString();
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
      body: SafeArea(
        bottom: false,
        child: state.loading
            ? Center(child: CircularProgressIndicator(color: palette.accent))
            : ListView(
                padding: const EdgeInsets.fromLTRB(22, 12, 22, 140),
                children: [
                  Row(
                    children: [
                      SquareIconButton(
                        icon: Icons.arrow_back_rounded,
                        onPressed: () => Navigator.of(context).maybePop(),
                      ),
                      const SizedBox(width: 14),
                      Text(l10n.profileTitle,
                          style: AppTypography.title3.copyWith(color: palette.textPrimary)),
                    ],
                  ),
                  const SizedBox(height: 22),
                  _AvatarPicker(palette: palette, saving: state.saving),
                  const SizedBox(height: 22),
                  SectionLabel(l10n.authDisplayNameLabel),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 54,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: palette.glassFill,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: palette.accent, width: 2),
                          ),
                          child: TextField(
                            controller: _displayName,
                            style: AppTypography.headline.copyWith(color: palette.textPrimary, fontSize: 17),
                            cursorColor: palette.accent,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintText: l10n.authDisplayNameHint,
                              hintStyle: AppTypography.label
                                  .copyWith(color: palette.textTertiary, fontWeight: FontWeight.w400),
                            ),
                            onSubmitted: (_) => _saveDisplayName(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Material(
                        color: palette.accentSoft,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: state.saving ? null : _saveDisplayName,
                          child: Container(
                            height: 54,
                            width: 54,
                            alignment: Alignment.center,
                            child: Icon(Icons.check_rounded, size: 18, color: palette.accent),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  GlassSurface(
                    radius: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.profileEmail,
                            style: AppTypography.caption.copyWith(color: palette.textSecondary)),
                        const SizedBox(height: 3),
                        Text(state.email ?? '—',
                            style: AppTypography.label.copyWith(color: palette.textPrimary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  SectionLabel(l10n.profileLanguage),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _LanguageOption(
                          code: 'TR',
                          label: l10n.profileLanguageTurkish,
                          selected: state.language == 'tr',
                          palette: palette,
                          onTap: () => controller.savePreferences(language: 'tr'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _LanguageOption(
                          code: 'EN',
                          label: l10n.profileLanguageEnglish,
                          selected: state.language == 'en',
                          palette: palette,
                          onTap: () => controller.savePreferences(language: 'en'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SectionLabel(l10n.profileBirthYear),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 54,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          alignment: Alignment.centerLeft,
                          decoration: BoxDecoration(
                            color: palette.glassFill,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: palette.accent, width: 2),
                          ),
                          child: TextField(
                            controller: _birthYear,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(4),
                            ],
                            style: AppTypography.headline.copyWith(
                              color: palette.textPrimary,
                              fontSize: 17,
                              letterSpacing: 1,
                            ),
                            cursorColor: palette.accent,
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                              hintText: l10n.profileBirthYearHint,
                              hintStyle: AppTypography.label
                                  .copyWith(color: palette.textTertiary, fontWeight: FontWeight.w400),
                            ),
                            onSubmitted: (_) => _saveBirthYear(l10n),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Material(
                        color: palette.accentSoft,
                        borderRadius: BorderRadius.circular(16),
                        clipBehavior: Clip.antiAlias,
                        child: InkWell(
                          onTap: state.saving ? null : () => _saveBirthYear(l10n),
                          child: Container(
                            height: 54,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                if (state.age != null) ...[
                                  Text(l10n.profileAgeValue(state.age!),
                                      style: AppTypography.label.copyWith(
                                          color: palette.accent, fontWeight: FontWeight.w600)),
                                  const SizedBox(width: 9),
                                ],
                                Icon(Icons.check_rounded, size: 18, color: palette.accent),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(l10n.profileAgeWhy,
                      style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
                  const SizedBox(height: 22),
                  GlassSurface(
                    radius: 16,
                    padding: EdgeInsets.zero,
                    child: InkWell(
                      onTap: () => context.go('/settings/diagnoses'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 60),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(l10n.profileDiagnoses,
                                      style: AppTypography.label
                                          .copyWith(color: palette.textPrimary)),
                                  const SizedBox(height: 2),
                                  Text(l10n.diagnosesSelectedCount(state.diagnoses.length),
                                      style: AppTypography.footnote
                                          .copyWith(color: palette.textSecondary)),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right_rounded,
                                size: 20, color: palette.textTertiary),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (state.error != null) ...[
                    const SizedBox(height: 16),
                    Text(friendlyErrorMessage(l10n, state.error!),
                        style: TextStyle(color: palette.warning)),
                  ],
                  const SizedBox(height: 26),
                  const _AppearanceGroup(),
                ],
              ),
      ),
    );
  }
}

/// Light/dark/system, at the bottom of the profile rather than in
/// Settings: it's a preference about how *your* app looks, next to the
/// rest of what makes the account yours.
class _AppearanceGroup extends ConsumerWidget {
  const _AppearanceGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final mode = ref.watch(themeModeControllerProvider);
    final controller = ref.read(themeModeControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(l10n.settingsAppearance),
        const SizedBox(height: 8),
        GlassSurface(
          radius: 16,
          padding: const EdgeInsets.all(6),
          child: Row(
            children: [
              _ThemeOption(
                icon: Icons.smartphone_rounded,
                label: l10n.settingsThemeSystem,
                selected: mode == ThemeMode.system,
                palette: palette,
                onTap: () => controller.setMode(ThemeMode.system),
              ),
              const SizedBox(width: 6),
              _ThemeOption(
                icon: Icons.light_mode_outlined,
                label: l10n.settingsThemeLight,
                selected: mode == ThemeMode.light,
                palette: palette,
                onTap: () => controller.setMode(ThemeMode.light),
              ),
              const SizedBox(width: 6),
              _ThemeOption(
                icon: Icons.dark_mode_outlined,
                label: l10n.settingsThemeDark,
                selected: mode == ThemeMode.dark,
                palette: palette,
                onTap: () => controller.setMode(ThemeMode.dark),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ThemeOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  const _ThemeOption({
    required this.icon,
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: selected ? palette.accent : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, size: 18, color: selected ? Colors.white : palette.textSecondary),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: selected ? Colors.white : palette.textSecondary,
                    fontWeight: FontWeight.w600,
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

/// The circular photo at the top of the profile form, with a small
/// camera-badge button that opens the gallery picker. `saving` disables the
/// badge mid-upload rather than hiding it, so the circle doesn't jump.
class _AvatarPicker extends ConsumerWidget {
  final AppPalette palette;
  final bool saving;

  const _AvatarPicker({required this.palette, required this.saving});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final avatar = ref.watch(avatarBytesProvider);
    final controller = ref.read(profileControllerProvider.notifier);

    return Center(
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 88,
            height: 88,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(shape: BoxShape.circle, color: palette.surfaceMuted),
            child: avatar.when(
              data: (bytes) => bytes != null
                  ? Image.memory(bytes, fit: BoxFit.cover, width: 88, height: 88)
                  : Icon(Icons.person_rounded, size: 44, color: palette.textTertiary),
              loading: () =>
                  Center(child: CircularProgressIndicator(strokeWidth: 2, color: palette.accent)),
              error: (_, _) => Icon(Icons.person_rounded, size: 44, color: palette.textTertiary),
            ),
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Material(
              color: palette.accent,
              shape: const CircleBorder(),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: saving ? null : controller.pickAndUploadAvatar,
                child: const SizedBox(
                  width: 30,
                  height: 30,
                  child: Icon(Icons.camera_alt_rounded, size: 15, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LanguageOption extends StatelessWidget {
  final String code;
  final String label;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  const _LanguageOption({
    required this.code,
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? palette.accent : palette.glassFill,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? palette.accent : palette.separator),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                code,
                style: AppTypography.headline.copyWith(
                  fontSize: 19,
                  color: selected ? Colors.white : palette.textPrimary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.85)
                      : palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
