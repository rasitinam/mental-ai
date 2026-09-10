import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/data/profile_api.dart';
import '../../profile/presentation/profile_controller.dart';

/// The account's "Gizlilik" (Privacy) sub-page, reached from Hesap. Holds
/// message privacy today — who may open a DM thread with you — and is
/// where any future privacy toggle (who sees a follower list, etc.)
/// belongs, rather than growing the top-level Hesap group.
class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);

    return Scaffold(
      body: SafeArea(
        bottom: false,
        // 140 rather than 24: this route lives inside the shell, so
        // `HomeShell`'s floating nav bar sits on top of the last ~100px.
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 140),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  SquareIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 14),
                  Text(l10n.settingsPrivacyRow,
                      style: AppTypography.title3.copyWith(color: palette.textPrimary)),
                ],
              ),
              const SizedBox(height: 22),
              const Expanded(child: SingleChildScrollView(child: _DmPolicyGroup())),
            ],
          ),
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
