import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/layout/bottom_clearance.dart';
import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/components.dart';
import '../../../app/theme/glass.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/network/error_messages.dart';
import '../../../core/storage/local_prefs.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/data/profile_api.dart';

/// The person's answer to "may Hearth send your content to OpenAI?", as far
/// as this session knows it: `null` until the profile has been read. The
/// server is the source of truth — every AI endpoint refuses without it —
/// this copy only decides whether the router asks. Reset on sign-in/out.
final aiConsentProvider = StateProvider<bool?>((ref) {
  ref.watch(sessionTokenProvider);
  return null;
});

/// Set when this session couldn't read the answer (offline), so the router
/// doesn't wait on the network again at every navigation.
final _aiConsentUnreadableProvider = StateProvider<bool>((ref) {
  ref.watch(sessionTokenProvider);
  return false;
});

/// Whether the router should show [AiConsentScreen] now: they haven't
/// allowed it, and haven't already said no on this device. Reads the
/// server once per session; `false` when it can't be read (offline) — the
/// server still refuses anything that would need the permission.
Future<bool> shouldAskAiConsent(Ref ref) async {
  var granted = ref.read(aiConsentProvider);
  final prefs = ref.read(sharedPreferencesProvider);
  if (granted == null) {
    if (ref.read(_aiConsentUnreadableProvider)) return false;
    try {
      granted = (await ref.read(profileApiProvider).profile()).aiConsent;
      ref.read(aiConsentProvider.notifier).state = granted;
    } catch (_) {
      ref.read(_aiConsentUnreadableProvider.notifier).state = true;
      return false;
    }
  }
  if (granted) return false;
  final declinedBy = prefs.getString(AppConstants.prefsAiConsentDeclinedKey);
  return declinedBy == null || declinedBy != prefs.getString(AppConstants.prefsUserIdKey);
}

/// Asked once, after sign-in and before any AI feature: what goes to the
/// AI service, who receives it, and a plain yes or no. Nothing of theirs
/// goes to OpenAI until they say yes here (App Store guideline 5.1.2(i)).
/// Also opened from Me › Privacy to read the details and answer again.
class AiConsentScreen extends ConsumerStatefulWidget {
  /// Called with the stored answer.
  final void Function(bool granted) onDone;

  /// Opened from settings: shows a back button.
  final bool fromSettings;

  const AiConsentScreen({super.key, required this.onDone, this.fromSettings = false});

  @override
  ConsumerState<AiConsentScreen> createState() => _AiConsentScreenState();
}

class _AiConsentScreenState extends ConsumerState<AiConsentScreen> {
  /// The answer being saved, or `null` while nothing is in flight.
  bool? _saving;
  Object? _error;

  Future<void> _answer(bool granted) async {
    if (_saving != null) return;
    setState(() {
      _saving = granted;
      _error = null;
    });
    try {
      final stored = await ref.read(profileApiProvider).setAiConsent(granted);
      final prefs = ref.read(sharedPreferencesProvider);
      final userId = prefs.getString(AppConstants.prefsUserIdKey);
      if (stored || userId == null) {
        await prefs.remove(AppConstants.prefsAiConsentDeclinedKey);
      } else {
        await prefs.setString(AppConstants.prefsAiConsentDeclinedKey, userId);
      }
      ref.read(aiConsentProvider.notifier).state = stored;
      ref.invalidate(myProfileProvider);
      if (!mounted) return;
      widget.onDone(stored);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _saving = null;
        _error = e;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);

    final sent = [
      (Icons.chat_bubble_outline_rounded, l10n.aiConsentWhatChat),
      (Icons.edit_note_rounded, l10n.aiConsentWhatEntries),
      (Icons.person_outline_rounded, l10n.aiConsentWhatProfile),
      (Icons.translate_rounded, l10n.aiConsentWhatStories),
    ];

    Widget paragraph(String text) =>
        Text(text, style: AppTypography.subheadline.copyWith(color: palette.textPrimary, height: 1.45));

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: widget.fromSettings
                        ? SquareIconButton(
                            icon: Icons.arrow_back_rounded,
                            onPressed: () => Navigator.of(context).maybePop(),
                          )
                        : Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(color: palette.sky, borderRadius: BorderRadius.circular(14)),
                            child: Icon(Icons.auto_awesome_outlined, size: 24, color: palette.onTint),
                          ),
                  ),
                  const SizedBox(height: 22),
                  Text(l10n.aiConsentTitle, style: AppTypography.largeTitle.copyWith(color: palette.textPrimary)),
                  const SizedBox(height: 8),
                  Text(l10n.aiConsentLead,
                      style: AppTypography.body.copyWith(color: palette.textSecondary, height: 1.45)),
                  const SizedBox(height: 24),
                  SectionLabel(l10n.aiConsentWhatTitle),
                  const SizedBox(height: 8),
                  GlassSurface(
                    radius: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    child: Column(
                      children: [
                        for (final (i, (icon, text)) in sent.indexed) ...[
                          if (i > 0) Divider(height: 1, thickness: 1, color: palette.separator),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(icon, size: 20, color: palette.textSecondary),
                                const SizedBox(width: 12),
                                Expanded(child: paragraph(text)),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SectionLabel(l10n.aiConsentWhoTitle),
                  const SizedBox(height: 8),
                  paragraph(l10n.aiConsentWhoBody),
                  const SizedBox(height: 22),
                  SectionLabel(l10n.aiConsentChoiceTitle),
                  const SizedBox(height: 8),
                  paragraph(l10n.aiConsentChoiceBody),
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
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_error != null) ...[
                      Text(friendlyErrorMessage(l10n, _error!),
                          textAlign: TextAlign.center,
                          style: AppTypography.footnote.copyWith(color: palette.warning)),
                      const SizedBox(height: 10),
                    ],
                    AppPrimaryButton(
                      label: l10n.aiConsentAllow,
                      loading: _saving == true,
                      onPressed: _saving == null ? () => _answer(true) : null,
                    ),
                    const SizedBox(height: 10),
                    OutlineBlockButton(
                      label: l10n.aiConsentDecline,
                      onTap: _saving == null ? () => _answer(false) : null,
                    ),
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
