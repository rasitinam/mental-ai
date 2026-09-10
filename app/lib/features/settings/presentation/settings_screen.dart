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
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 140),
          children: [
            Text(l10n.settingsTitle,
                style: AppTypography.title2.copyWith(color: palette.textPrimary)),
            const SizedBox(height: 20),
            _Group(
              title: l10n.settingsAccount,
              children: [
                _Row(label: l10n.settingsProfile, onTap: () => context.go('/settings/profile')),
                _Row(label: l10n.settingsAssessment, onTap: () => context.go('/settings/assessment')),
                _Row(
                  label: l10n.settingsLogout,
                  labelColor: palette.warning,
                  onTap: () => _logout(context, ref),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Group(
              title: l10n.settingsCommunity,
              children: [
                _Row(
                  label: l10n.settingsStories,
                  onTap: () => context.go('/settings/stories'),
                ),
                if (isAdmin)
                  _Row(
                    label: l10n.settingsModeration,
                    badge: l10n.settingsAdminBadge,
                    onTap: () => context.go('/settings/stories/moderation'),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            const _AppearanceGroup(),
            const SizedBox(height: 20),
            _Group(
              title: l10n.settingsPrivacy,
              children: [
                _Row(label: l10n.settingsDataLocation, description: l10n.settingsDataLocationBody),
                _Row(label: l10n.settingsLegal, description: l10n.settingsLegalBody),
              ],
            ),
            const SizedBox(height: 20),
            _Group(
              title: l10n.settingsConnection,
              children: [
                _Row(label: l10n.settingsServer, value: AppConstants.apiBaseUrl),
                _Row(label: l10n.settingsDeviceId, value: userId),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _Group({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(title),
        const SizedBox(height: 8),
        GlassSurface(
          radius: 16,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  Divider(height: 1, thickness: 1, color: palette.separator),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// One settings line. Three shapes in one widget because the design uses
/// exactly three: a read-only value on the right, a paragraph under the
/// label, or a chevron that goes somewhere.
class _Row extends StatelessWidget {
  final String label;
  final String? value;
  final String? description;
  final String? badge;
  final Color? labelColor;
  final VoidCallback? onTap;

  const _Row({
    required this.label,
    this.value,
    this.description,
    this.badge,
    this.labelColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(label,
                            style: AppTypography.label
                                .copyWith(color: labelColor ?? palette.textPrimary)),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 9),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: palette.surfaceMuted,
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            badge!.toUpperCase(),
                            style: TextStyle(
                              fontSize: 10.5,
                              height: 1.2,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.42,
                              color: palette.textSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (description != null) ...[
                    const SizedBox(height: 3),
                    Text(description!,
                        style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
                  ],
                ],
              ),
            ),
            if (value != null)
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 170),
                child: Text(
                  value!,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.footnote
                      .copyWith(color: palette.textSecondary, fontSize: 13),
                ),
              ),
            if (onTap != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, size: 20, color: palette.textTertiary),
            ],
          ],
        ),
      ),
    );
  }
}

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
