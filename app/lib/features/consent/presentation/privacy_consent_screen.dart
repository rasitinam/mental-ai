import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/l10n/locale_controller.dart';
import '../../../core/storage/local_prefs.dart';
import '../../../l10n/app_localizations.dart';

/// The version of the hosted Privacy Policy this summary describes. Bump
/// it when the policy changes materially and everyone sees the summary
/// once more.
const privacyPolicyVersion = '2026-09-15';

bool hasAcceptedPrivacy(SharedPreferences prefs) =>
    prefs.getString(AppConstants.prefsPrivacyAcceptedKey) == privacyPolicyVersion;

/// "Before you go": a short summary of the Privacy Policy, shown once on
/// the first launch (and again after a policy version bump). Sliding to
/// accept is the explicit consent the policy relies on for health data.
class PrivacyConsentScreen extends ConsumerWidget {
  final VoidCallback onAccepted;

  const PrivacyConsentScreen({super.key, required this.onAccepted});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final language = ref.watch(localeControllerProvider).languageCode;

    final points = [
      (Icons.lock_outline_rounded, palette.sun, l10n.consentOwnTitle, l10n.consentOwnBody),
      (Icons.auto_awesome_outlined, palette.sky, l10n.consentAiTitle, l10n.consentAiBody),
      (Icons.favorite_border_rounded, palette.peach, l10n.consentHealthTitle, l10n.consentHealthBody),
      (Icons.delete_outline_rounded, palette.mint, l10n.consentDeleteTitle, l10n.consentDeleteBody),
      (Icons.health_and_safety_outlined, palette.lilac, l10n.consentCareTitle, l10n.consentCareBody),
    ];

    Future<void> accept() async {
      await ref.read(sharedPreferencesProvider).setString(AppConstants.prefsPrivacyAcceptedKey, privacyPolicyVersion);
      onAccepted();
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
                children: [
                  Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(color: palette.textPrimary, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Text('Hearth', style: AppTypography.headline.copyWith(color: palette.textPrimary)),
                      const Spacer(),
                      _LanguageSwitch(
                        selected: language,
                        onChanged: (code) => ref.read(localeControllerProvider.notifier).setLanguage(code),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  Text(l10n.consentTitle, style: AppTypography.largeTitle.copyWith(color: palette.textPrimary)),
                  const SizedBox(height: 8),
                  Text(l10n.consentLead, style: AppTypography.body.copyWith(color: palette.textSecondary, height: 1.45)),
                  const SizedBox(height: 22),
                  for (final (icon, tint, title, body) in points) ...[
                    _Point(icon: icon, tint: tint, title: title, body: body),
                    const SizedBox(height: 10),
                  ],
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: palette.textPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                      ),
                      onPressed: () => launchUrl(
                        Uri.parse('${AppConstants.privacyPolicyUrl}?lang=$language'),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: Text(
                        l10n.consentReadFull,
                        style: AppTypography.label.copyWith(
                          color: palette.textPrimary,
                          fontWeight: FontWeight.w700,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                color: palette.canvasTop,
                border: Border(top: BorderSide(color: palette.separator)),
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(22, 14, 22, bottomClearance(context, gap: 16)),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  // Stretch, so the slider gets the full width instead of
                  // shrinking to its handle.
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.consentFinePrint,
                      textAlign: TextAlign.center,
                      style: AppTypography.footnote.copyWith(color: palette.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    SlideToAccept(label: l10n.consentSlide, doneLabel: l10n.consentAccepted, onAccepted: accept),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Point extends StatelessWidget {
  final IconData icon;
  final Color tint;
  final String title;
  final String body;

  const _Point({required this.icon, required this.tint, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return GlassSurface(
      radius: 20,
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(color: tint, borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, size: 22, color: palette.onTint),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.label.copyWith(color: palette.textPrimary, fontWeight: FontWeight.w700, fontSize: 16)),
                const SizedBox(height: 3),
                Text(body, style: AppTypography.subheadline.copyWith(color: palette.textSecondary, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Each language is named in itself, so someone who can't read the
/// current one still finds their own.
class _LanguageSwitch extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onChanged;

  const _LanguageSwitch({required this.selected, required this.onChanged});

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

/// A track with a round handle: drag the handle to the end to accept.
/// Letting go early slides it back. Screen readers get a plain "activate"
/// action instead, since they can't perform the drag.
class SlideToAccept extends StatefulWidget {
  final String label;
  final String doneLabel;
  final Future<void> Function() onAccepted;

  const SlideToAccept({super.key, required this.label, required this.doneLabel, required this.onAccepted});

  @override
  State<SlideToAccept> createState() => _SlideToAcceptState();
}

class _SlideToAcceptState extends State<SlideToAccept> {
  static const _height = 64.0;
  static const _inset = 5.0;
  static const _handle = _height - _inset * 2;
  static const _threshold = 0.85;

  double _progress = 0;
  bool _dragging = false;
  bool _done = false;

  Future<void> _accept() async {
    if (_done) return;
    setState(() {
      _done = true;
      _dragging = false;
      _progress = 1;
    });
    HapticFeedback.mediumImpact();
    await widget.onAccepted();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Semantics(
      button: true,
      enabled: !_done,
      label: _done ? widget.doneLabel : widget.label,
      onTap: _done ? null : _accept,
      excludeSemantics: true,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final travel = constraints.maxWidth - _handle - _inset * 2;
          final duration = _dragging ? Duration.zero : const Duration(milliseconds: 280);

          return GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragStart: _done ? null : (_) => setState(() => _dragging = true),
            onHorizontalDragUpdate: _done
                ? null
                : (details) => setState(() => _progress = (_progress + details.delta.dx / travel).clamp(0.0, 1.0)),
            onHorizontalDragEnd: _done
                ? null
                : (_) {
                    if (_progress >= _threshold) {
                      _accept();
                    } else {
                      setState(() {
                        _dragging = false;
                        _progress = 0;
                      });
                    }
                  },
            child: Container(
              height: _height,
              decoration: BoxDecoration(
                color: palette.glassFill,
                borderRadius: BorderRadius.circular(_height / 2),
                border: Border.all(color: palette.glassBorder, width: 1.5),
              ),
              child: Stack(
                children: [
                  AnimatedContainer(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.all(_inset - 1.5),
                    width: _handle + _progress * travel,
                    decoration: BoxDecoration(
                      color: palette.mint,
                      borderRadius: BorderRadius.circular(_handle / 2),
                    ),
                  ),
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.only(left: _handle + _inset * 2, right: 16),
                      child: Center(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 150),
                          opacity: _done ? 0 : (1 - _progress * 1.6).clamp(0.0, 1.0),
                          child: Text(
                            widget.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.label.copyWith(
                              color: palette.textPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  AnimatedPositioned(
                    duration: duration,
                    curve: Curves.easeOutCubic,
                    left: _inset - 1.5 + _progress * travel,
                    top: _inset - 1.5,
                    child: Container(
                      width: _handle,
                      height: _handle,
                      decoration: BoxDecoration(color: palette.accent, shape: BoxShape.circle),
                      child: Icon(
                        _done ? Icons.check_rounded : Icons.arrow_forward_rounded,
                        color: palette.onAccent,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
