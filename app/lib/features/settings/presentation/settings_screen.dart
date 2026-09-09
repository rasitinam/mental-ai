import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/storage/local_prefs.dart';
import '../../../core/theme/theme_mode_controller.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/auth_api.dart';
import '../../profile/data/profile_api.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authApiProvider).logout();
    } catch (_) {
      // Best-effort: even if the network call fails, clearing the local
      // session still logs the person out of this device.
    }
    final prefs = ref.read(sharedPreferencesProvider);
    await clearSession(prefs);
    ref.read(sessionTokenProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final userId = ref.watch(currentUserIdProvider);
    final palette = AppPalette.of(context);
    final isAdmin = ref.watch(myProfileProvider).valueOrNull?.isAdmin ?? false;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.settingsTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
        children: [
          _SettingsGroup(
            title: l10n.settingsConnection,
            rows: [
              _SettingsRow(
                  icon: Icons.dns_outlined,
                  label: l10n.settingsServer,
                  value: AppConstants.apiBaseUrl),
              _SettingsRow(
                  icon: Icons.fingerprint_rounded, label: l10n.settingsDeviceId, value: userId),
            ],
          ),
          const SizedBox(height: 20),
          _AppearanceGroup(title: l10n.settingsAppearance),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: l10n.settingsPrivacy,
            rows: [
              _SettingsRow(
                icon: Icons.lock_outline_rounded,
                label: l10n.settingsDataLocation,
                description: l10n.settingsDataLocationBody,
              ),
              _SettingsRow(
                icon: Icons.shield_outlined,
                label: l10n.settingsLegal,
                description: l10n.settingsLegalBody,
              ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: l10n.settingsCommunity,
            rows: [
              _SettingsRow(
                icon: Icons.auto_stories_outlined,
                label: l10n.settingsStories,
                description: l10n.settingsStoriesBody,
                onTap: () => context.go('/settings/stories'),
              ),
              if (isAdmin)
                _SettingsRow(
                  icon: Icons.fact_check_outlined,
                  label: l10n.settingsModeration,
                  description: l10n.settingsModerationBody,
                  onTap: () => context.go('/settings/stories/moderation'),
                ),
            ],
          ),
          const SizedBox(height: 20),
          _SettingsGroup(
            title: l10n.settingsAccount,
            rows: [
              _SettingsRow(
                icon: Icons.person_outline_rounded,
                label: l10n.settingsProfile,
                description: l10n.settingsProfileBody,
                onTap: () => context.go('/settings/profile'),
              ),
              _SettingsRow(
                icon: Icons.logout_rounded,
                label: l10n.settingsLogout,
                iconColor: palette.warning,
                onTap: () => _logout(context, ref),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AppearanceGroup extends ConsumerWidget {
  final String title;
  const _AppearanceGroup({required this.title});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final mode = ref.watch(themeModeControllerProvider);
    final controller = ref.read(themeModeControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.caption.copyWith(color: palette.textTertiary, letterSpacing: 0.6),
          ),
        ),
        GlassSurface(
          radius: 22,
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
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Icon(icon, size: 18, color: selected ? palette.canvasBottom : palette.textSecondary),
                const SizedBox(height: 6),
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: selected ? palette.canvasBottom : palette.textSecondary,
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

class _SettingsGroup extends StatelessWidget {
  final String title;
  final List<_SettingsRow> rows;
  const _SettingsGroup({required this.title, required this.rows});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.caption.copyWith(color: palette.textTertiary, letterSpacing: 0.6),
          ),
        ),
        GlassSurface(
          radius: 22,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                rows[i],
                if (i != rows.length - 1) Divider(height: 1, indent: 56, color: palette.separator),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final String? description;
  final Color? iconColor;
  final VoidCallback? onTap;

  const _SettingsRow({
    required this.icon,
    required this.label,
    this.value,
    this.description,
    this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 20, color: iconColor ?? palette.accent),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTypography.headline.copyWith(color: iconColor ?? palette.textPrimary),
                  ),
                  if (value != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      value!,
                      style: AppTypography.footnote.copyWith(color: palette.textSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (description != null) ...[
                    const SizedBox(height: 3),
                    Text(description!, style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
