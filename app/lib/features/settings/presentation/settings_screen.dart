import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
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
import '../../notifications/push_service.dart';
import '../../profile/data/profile_api.dart';
import '../../social/data/dm_entry.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    // Before the session goes away — unregistering needs the auth token
    // that's about to be cleared, and needs to happen at all, or this
    // device keeps getting pushes for an account no longer signed in on it.
    if (!kIsWeb) {
      await ref.read(pushServiceProvider).unregister();
    }
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

  Future<void> _deleteAccount(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final passwordController = TextEditingController();

    final deleted = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, setState) {
          String? error;
          var busy = false;

          Future<void> confirm() async {
            setState(() {
              busy = true;
              error = null;
            });
            try {
              await ref.read(authApiProvider).deleteAccount(password: passwordController.text);
              if (dialogContext.mounted) Navigator.pop(dialogContext, true);
            } on DioException catch (e) {
              setState(() {
                busy = false;
                error = e.response?.statusCode == 401 ? l10n.deleteAccountWrongPassword : l10n.commonError;
              });
            }
          }

          return AlertDialog(
            backgroundColor: palette.glassFill,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(l10n.deleteAccountTitle,
                style: AppTypography.headline.copyWith(color: palette.textPrimary, fontSize: 17)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.deleteAccountBody,
                    style: AppTypography.footnote.copyWith(color: palette.textSecondary, height: 1.5)),
                const SizedBox(height: 14),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  onChanged: (_) => setState(() {}),
                  style: AppTypography.subheadline.copyWith(color: palette.textPrimary),
                  cursorColor: palette.warning,
                  decoration: InputDecoration(
                    hintText: l10n.deleteAccountPasswordHint,
                    hintStyle: AppTypography.subheadline.copyWith(color: palette.textTertiary),
                    errorText: error,
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: busy ? null : () => Navigator.pop(dialogContext, false),
                child: Text(l10n.commonCancel),
              ),
              TextButton(
                onPressed: busy || passwordController.text.isEmpty ? null : confirm,
                child: Text(l10n.deleteAccountConfirm, style: TextStyle(color: palette.warning)),
              ),
            ],
          );
        },
      ),
    );
    if (deleted != true || !context.mounted) return;

    // Queued before the token clears, so it's on this (still current)
    // screen's ScaffoldMessenger rather than racing the router's redirect
    // to the login screen that clearing the token triggers.
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.deleteAccountDone)));

    // Same local cleanup as logout — the account (and its push
    // registration) is already gone server-side at this point.
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
              children: [
                _Row(
                  label: l10n.settingsPremiumRow,
                  labelColor: palette.accent,
                  onTap: () => context.push('/premium'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            _Group(
              title: l10n.settingsAccount,
              children: [
                _Row(label: l10n.settingsProfile, onTap: () => context.go('/settings/profile')),
                _Row(label: l10n.settingsAssessment, onTap: () => context.go('/settings/assessment')),
                _Row(label: l10n.settingsMyStories, onTap: () => context.go('/settings/my-stories')),
                _Row(
                  label: l10n.dmTitle,
                  onTap: () {
                    // Read by `HomeShell`'s back handling: entering
                    // Messages from here means Android back should
                    // return here too, not fall through to Stories.
                    ref.read(dmEnteredFromSettingsProvider.notifier).state = true;
                    context.go('/dm');
                  },
                ),
                _Row(label: l10n.settingsPrivacyRow, onTap: () => context.go('/settings/privacy')),
              ],
            ),
            const SizedBox(height: 20),
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
                _Row(
                  label: l10n.settingsDeleteAccount,
                  labelColor: palette.warning,
                  onTap: () => _deleteAccount(context, ref),
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

