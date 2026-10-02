import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
import '../../consent/presentation/ai_consent_screen.dart';
import '../../profile/data/profile_api.dart';
import '../../profile/presentation/profile_controller.dart';

/// The account's "Gizlilik" (Privacy) sub-page, reached from Hesap. Holds
/// sharing with the AI service and message privacy — who may open a DM thread with you — and is
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
        // Inside the shell: clear the floating tab bar (see `bottomClearance`).
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 12, 22, bottomClearance(context)),
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
              const Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [_AiSharingGroup(), SizedBox(height: 28), _DmPolicyGroup()],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Whether their content may be sent to the AI service (OpenAI): the same
/// permission the AI consent screen asks for, withdrawable here at any time.
/// Turning it on goes through that screen, so the details are always read
/// before saying yes; turning it off takes effect at once.
class _AiSharingGroup extends ConsumerStatefulWidget {
  const _AiSharingGroup();

  @override
  ConsumerState<_AiSharingGroup> createState() => _AiSharingGroupState();
}

class _AiSharingGroupState extends ConsumerState<_AiSharingGroup> {
  bool _saving = false;

  void _openDetails() {
    Navigator.of(context).push(MaterialPageRoute<void>(
      builder: (context) => AiConsentScreen(
        fromSettings: true,
        onDone: (_) => Navigator.of(context).pop(),
      ),
    ));
  }

  Future<void> _turnOff() async {
    setState(() => _saving = true);
    try {
      await ref.read(profileApiProvider).setAiConsent(false);
      ref.read(aiConsentProvider.notifier).state = false;
      ref.invalidate(myProfileProvider);
    } catch (_) {
      // The switch stays on: the profile still says so.
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final granted = ref.watch(myProfileProvider).valueOrNull?.aiConsent ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(l10n.settingsAiSharingLabel),
        const SizedBox(height: 8),
        GlassSurface(
          radius: 16,
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 10, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(l10n.settingsAiSharingTitle,
                          style: AppTypography.label.copyWith(color: palette.textPrimary)),
                    ),
                    Switch(
                      value: granted,
                      activeThumbColor: palette.accent,
                      onChanged: _saving ? null : (on) => on ? _openDetails() : _turnOff(),
                    ),
                  ],
                ),
              ),
              Divider(height: 1, thickness: 1, color: palette.separator),
              InkWell(
                onTap: _openDetails,
                child: Container(
                  constraints: const BoxConstraints(minHeight: 52),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(l10n.settingsAiSharingDetails,
                            style: AppTypography.label.copyWith(color: palette.textPrimary)),
                      ),
                      Icon(Icons.chevron_right_rounded, size: 22, color: palette.textSecondary),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text(l10n.settingsAiSharingBody,
            style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
      ],
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
