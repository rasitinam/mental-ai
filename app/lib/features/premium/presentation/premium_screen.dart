import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/error_messages.dart';
import '../../../l10n/app_localizations.dart';
import 'premium_controller.dart';

/// The Hearth Plus paywall. Every subscription screen Apple approves shows
/// the same four things (App Store Review Guideline 3.1.2): what it is,
/// how long it runs, what it costs, and a way to read the actual terms —
/// this screen exists to carry exactly those, not to be clever about it.
class PremiumScreen extends ConsumerWidget {
  const PremiumScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final state = ref.watch(premiumControllerProvider);
    final controller = ref.read(premiumControllerProvider.notifier);
    final locale = Localizations.localeOf(context).languageCode;

    ref.listen(premiumControllerProvider, (prev, next) {
      if (next.restoring == false && prev?.restoring == true && next.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.premiumRestored)));
      }
    });

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(22, 12, 22, bottomClearance(context)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  SquareIconButton(
                    icon: Icons.arrow_back_rounded,
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.premiumTitle,
                          style: AppTypography.title2.copyWith(color: palette.textPrimary, fontSize: 26)),
                      const SizedBox(height: 6),
                      Text(l10n.premiumPitch,
                          style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
                      const SizedBox(height: 24),
                      GlassSurface(
                        radius: 18,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Feature(icon: Icons.forum_rounded, label: l10n.premiumFeatureChat, palette: palette),
                            const SizedBox(height: 14),
                            _Feature(
                                icon: Icons.insights_rounded, label: l10n.premiumFeatureAnalysis, palette: palette),
                            const SizedBox(height: 14),
                            _Feature(
                                icon: Icons.auto_awesome_rounded,
                                label: l10n.premiumFeatureInsights,
                                palette: palette),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (state.entitlement.isPremium) ...[
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: palette.accentSoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_rounded, color: palette.accent, size: 20),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  state.entitlement.expiresAt == null
                                      ? l10n.premiumAlreadyActive
                                      : l10n.premiumActiveUntil(
                                          DateFormat.yMMMMd(locale).format(state.entitlement.expiresAt!)),
                                  style: AppTypography.footnote.copyWith(color: palette.accent),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else if (state.loadingProducts) ...[
                        Center(child: CircularProgressIndicator(color: palette.accent)),
                      ] else if (state.monthly == null) ...[
                        Text(l10n.premiumUnavailable,
                            style: AppTypography.footnote.copyWith(color: palette.warning)),
                      ] else ...[
                        Text(
                          l10n.premiumPricePerMonth(state.monthly!.price),
                          style: AppTypography.title2.copyWith(color: palette.textPrimary, fontSize: 22),
                        ),
                        const SizedBox(height: 16),
                        AppPrimaryButton(
                          label: l10n.premiumSubscribe,
                          loading: state.purchasing,
                          onPressed: state.purchasing ? null : controller.buy,
                        ),
                      ],
                      if (state.error != null) ...[
                        const SizedBox(height: 12),
                        Text(friendlyErrorMessage(l10n, state.error!),
                            style: AppTypography.footnote.copyWith(color: palette.warning)),
                      ],
                      const SizedBox(height: 16),
                      Center(
                        child: TextButton(
                          onPressed: state.restoring ? null : controller.restore,
                          child: Text(l10n.premiumRestore,
                              style: AppTypography.footnote.copyWith(color: palette.accent)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(l10n.premiumTerms,
                          style: AppTypography.caption.copyWith(color: palette.textTertiary, height: 1.5)),
                      if (AppConstants.privacyPolicyUrl.isNotEmpty ||
                          AppConstants.termsOfUseUrl.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 16,
                          children: [
                            if (AppConstants.privacyPolicyUrl.isNotEmpty)
                              _LegalLink(
                                label: l10n.premiumPrivacyPolicy,
                                url: AppConstants.privacyPolicyUrl,
                                palette: palette,
                              ),
                            if (AppConstants.termsOfUseUrl.isNotEmpty)
                              _LegalLink(
                                label: l10n.premiumTermsOfUse,
                                url: AppConstants.termsOfUseUrl,
                                palette: palette,
                              ),
                          ],
                        ),
                      ],
                    ],
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

class _Feature extends StatelessWidget {
  final IconData icon;
  final String label;
  final AppPalette palette;
  const _Feature({required this.icon, required this.label, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: palette.accent),
        const SizedBox(width: 12),
        Expanded(
          child: Text(label, style: AppTypography.subheadline.copyWith(color: palette.textPrimary)),
        ),
      ],
    );
  }
}

class _LegalLink extends StatelessWidget {
  final String label;
  final String url;
  final AppPalette palette;
  const _LegalLink({required this.label, required this.url, required this.palette});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(color: palette.textSecondary, decoration: TextDecoration.underline),
      ),
    );
  }
}
