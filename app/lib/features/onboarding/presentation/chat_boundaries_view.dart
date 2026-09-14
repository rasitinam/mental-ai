import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/network/error_messages.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/data/profile_api.dart';
import '../domain/chat_boundary_option.dart';

/// "What do you *not* want from these conversations?" — asked once,
/// before the screening battery, and reachable again from the profile.
///
/// It sits first in onboarding on purpose: every other question the app
/// asks is about what's wrong, and answering a page of those before
/// anyone has said how they want to be spoken to is the wrong order. The
/// answer is a standing instruction, not a measurement — see
/// `mental_domain::chat_boundary` for what each choice turns into.
class ChatBoundariesView extends ConsumerStatefulWidget {
  /// Shown above the actions when this is part of the onboarding run;
  /// the standalone (profile) entry passes its own back button instead.
  final bool onboarding;
  final List<String> initialBoundaries;
  final String? initialNote;

  /// Called after a successful save, and for the skip action in
  /// onboarding (`onSkip` null = no skip affordance, i.e. the profile
  /// entry, where leaving is just the back button).
  final VoidCallback onSaved;
  final VoidCallback? onSkip;

  const ChatBoundariesView({
    super.key,
    required this.onboarding,
    required this.onSaved,
    this.onSkip,
    this.initialBoundaries = const [],
    this.initialNote,
  });

  @override
  ConsumerState<ChatBoundariesView> createState() => _ChatBoundariesViewState();
}

class _ChatBoundariesViewState extends ConsumerState<ChatBoundariesView> {
  late final Set<String> _selected = {...widget.initialBoundaries};
  late final TextEditingController _note = TextEditingController(text: widget.initialNote ?? '');
  bool _saving = false;
  Object? _error;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(profileApiProvider).setChatBoundaries(
            boundaries: _selected.toList(),
            note: _note.text.trim().isEmpty ? null : _note.text.trim(),
          );
      // Hand control back before refreshing the profile: the refresh
      // rebuilds whatever is watching it, and this view is one of those
      // things on the settings entry — moving on first keeps that from
      // deciding whether the caller ever hears about the save.
      if (mounted) widget.onSaved();
      ref.invalidate(myProfileProvider);
    } catch (e) {
      if (mounted) {
        setState(() {
          _saving = false;
          _error = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final options = chatBoundaryOptions(l10n);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              Text(l10n.boundariesTitle,
                  style: AppTypography.largeTitle.copyWith(color: palette.textPrimary)),
              const SizedBox(height: 10),
              Text(l10n.boundariesIntro,
                  style: AppTypography.subheadline
                      .copyWith(color: palette.textSecondary, height: 1.55)),
              const SizedBox(height: 14),
              // The "why we're asking" line, styled as a quiet note
              // rather than a warning: this is the part that tells
              // someone their answer actually changes the replies.
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: palette.accentSoft,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome_rounded, size: 17, color: palette.accent),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        l10n.boundariesEffectNote,
                        style: AppTypography.footnote
                            .copyWith(color: palette.accent, height: 1.5, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              for (final option in options) ...[
                _BoundaryTile(
                  option: option,
                  selected: _selected.contains(option.slug),
                  palette: palette,
                  onTap: () => setState(() {
                    if (!_selected.remove(option.slug)) _selected.add(option.slug);
                  }),
                ),
                const SizedBox(height: 10),
              ],
              const SizedBox(height: 12),
              SectionLabel(l10n.boundariesNoteLabel),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: palette.glassFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: palette.separator),
                ),
                child: TextField(
                  controller: _note,
                  maxLines: 3,
                  minLines: 2,
                  maxLength: kBoundaryNoteMaxLength,
                  inputFormatters: [LengthLimitingTextInputFormatter(kBoundaryNoteMaxLength)],
                  style: AppTypography.subheadline.copyWith(color: palette.textPrimary),
                  cursorColor: palette.accent,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    counterStyle: AppTypography.caption.copyWith(color: palette.textTertiary),
                    hintText: l10n.boundariesNoteHint,
                    hintStyle: AppTypography.subheadline.copyWith(color: palette.textTertiary),
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(l10n.boundariesChangeLater,
                  style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
              if (_error != null) ...[
                const SizedBox(height: 14),
                Text(friendlyErrorMessage(l10n, _error!),
                    style: TextStyle(color: palette.warning)),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
        AppPrimaryButton(
          label: widget.onboarding ? l10n.boundariesContinue : l10n.commonSave,
          loading: _saving,
          onPressed: _saving ? null : _save,
        ),
        if (widget.onSkip != null) ...[
          const SizedBox(height: 6),
          Center(
            child: TextButton(
              onPressed: _saving ? null : widget.onSkip,
              child: Text(l10n.onboardingSkipStep,
                  style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
            ),
          ),
        ],
      ],
    );
  }
}

class _BoundaryTile extends StatelessWidget {
  final ChatBoundaryOption option;
  final bool selected;
  final AppPalette palette;
  final VoidCallback onTap;

  const _BoundaryTile({
    required this.option,
    required this.selected,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? palette.accentSoft : palette.glassFill,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: selected ? palette.accent : palette.separator,
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 1),
                decoration: BoxDecoration(
                  color: selected ? palette.accent : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  border: selected ? null : Border.all(color: palette.textTertiary, width: 1.5),
                ),
                child: selected
                    ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                    : null,
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.label,
                      style: AppTypography.label.copyWith(
                        color: selected ? palette.accent : palette.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      option.description,
                      style: AppTypography.footnote
                          .copyWith(color: palette.textSecondary, height: 1.45),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
