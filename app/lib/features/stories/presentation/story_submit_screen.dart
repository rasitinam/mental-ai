import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
import 'stories_controller.dart';

/// The write flow for a life story. Free text only — no separate
/// "medication" field — and shown together with a disclaimer and a
/// consent checkbox that must be ticked before submitting. See
/// `mental_domain::life_story` on the backend for why: this is meant to
/// read as one person's own account, not a searchable directory of who
/// recommends which drug.
class StorySubmitScreen extends ConsumerStatefulWidget {
  const StorySubmitScreen({super.key});

  @override
  ConsumerState<StorySubmitScreen> createState() => _StorySubmitScreenState();
}

class _StorySubmitScreenState extends ConsumerState<StorySubmitScreen> {
  final _controller = TextEditingController();
  bool _consent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    final ok = await ref
        .read(storiesControllerProvider.notifier)
        .submit(body: _controller.text.trim(), consent: _consent);
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.storiesSubmitSuccess)));
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.commonError)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final state = ref.watch(storiesControllerProvider);
    final canSubmit = _consent && _controller.text.trim().isNotEmpty && !state.submitting;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.storiesSubmitTitle)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              GlassSurface(
                radius: 20,
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, size: 18, color: palette.warning),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        l10n.storiesDisclaimer,
                        style: AppTypography.footnote.copyWith(color: palette.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              GlassSurface(
                radius: 26,
                padding: const EdgeInsets.all(4),
                child: TextField(
                  controller: _controller,
                  maxLines: 10,
                  minLines: 8,
                  onChanged: (_) => setState(() {}),
                  textAlignVertical: TextAlignVertical.top,
                  style: AppTypography.body.copyWith(color: palette.textPrimary),
                  cursorColor: palette.accent,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.all(18),
                    hintText: l10n.storiesSubmitHint,
                    hintStyle: AppTypography.body.copyWith(color: palette.textTertiary),
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () => setState(() => _consent = !_consent),
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _consent,
                        onChanged: (v) => setState(() => _consent = v ?? false),
                        activeColor: palette.accent,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            l10n.storiesConsentLabel,
                            style: AppTypography.footnote.copyWith(color: palette.textSecondary),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                l10n.storiesModerationNotice,
                style: AppTypography.footnote.copyWith(color: palette.textTertiary),
              ),
              const SizedBox(height: 20),
              if (state.error != null) ...[
                Text(state.error!, style: TextStyle(color: palette.warning), textAlign: TextAlign.center),
                const SizedBox(height: 12),
              ],
              AppPrimaryButton(
                label: l10n.storiesSubmit,
                loading: state.submitting,
                onPressed: canSubmit ? _submit : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
