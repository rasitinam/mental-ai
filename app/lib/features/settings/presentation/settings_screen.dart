import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/storage/local_prefs.dart';
import '../../../l10n/app_localizations.dart';
import '../../auth/data/auth_api.dart';
import '../../profile/data/profile_api.dart';
import '../../profile/presentation/profile_controller.dart';

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
                _Row(label: l10n.settingsMyStories, onTap: () => context.go('/settings/my-stories')),
                _Row(label: l10n.dmTitle, onTap: () => context.go('/dm')),
              ],
            ),
            const SizedBox(height: 20),
            const _DmPolicyGroup(),
            // Moderation is the only thing left in this group now that the
            // feed is a tab of its own, so for everyone but an admin the
            // group would be an empty card with a heading.
            if (isAdmin) ...[
              const SizedBox(height: 20),
              _Group(
                title: l10n.settingsCommunity,
                children: [
                  _Row(
                    label: l10n.settingsModeration,
                    badge: l10n.settingsAdminBadge,
                    onTap: () => context.go('/stories/moderation'),
                  ),
                ],
              ),
            ],
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
            const SizedBox(height: 20),
            _Group(
              children: [
                _Row(
                  label: l10n.settingsLogout,
                  labelColor: palette.warning,
                  onTap: () => _logout(context, ref),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Group extends StatelessWidget {
  /// Omitted for a group that needs no heading — the lone "log out" card
  /// at the very bottom, which a label would only make heavier.
  final String? title;
  final List<Widget> children;
  const _Group({this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null) ...[
          SectionLabel(title!),
          const SizedBox(height: 8),
        ],
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

/// Who may open a DM request. Reads the current value off the profile
/// (the same `/profile` the rest of the account settings use) and writes
/// it back through `savePreferences`, so there's no second source of
/// truth for one account preference.
class _DmPolicyGroup extends ConsumerWidget {
  const _DmPolicyGroup();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final policy = ref.watch(myProfileProvider).valueOrNull?.dmPolicy ?? 'everyone';
    final saving = ref.watch(profileControllerProvider.select((s) => s.saving));

    Future<void> set(String next) async {
      if (next == policy || saving) return;
      await ref.read(profileControllerProvider.notifier).savePreferences(dmPolicy: next);
      ref.invalidate(myProfileProvider);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(l10n.settingsDmPrivacy),
        const SizedBox(height: 8),
        GlassSurface(
          radius: 16,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _PolicyRow(
                label: l10n.settingsDmEveryone,
                selected: policy == 'everyone',
                palette: palette,
                onTap: () => set('everyone'),
              ),
              Divider(height: 1, thickness: 1, color: palette.separator),
              _PolicyRow(
                label: l10n.settingsDmFollowing,
                selected: policy == 'following',
                palette: palette,
                onTap: () => set('following'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(l10n.settingsDmNoReceipts,
            style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
      ],
    );
  }
}

class _PolicyRow extends StatelessWidget {
  final String label;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  const _PolicyRow({
    required this.label,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 56),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(label, style: AppTypography.label.copyWith(color: palette.textPrimary)),
            ),
            if (selected) Icon(Icons.check_rounded, size: 20, color: palette.accent),
          ],
        ),
      ),
    );
  }
}
