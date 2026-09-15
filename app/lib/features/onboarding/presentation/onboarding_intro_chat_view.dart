import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../core/network/error_messages.dart';
import '../../../l10n/app_localizations.dart';
import '../../profile/data/profile_api.dart';
import '../data/onboarding_api.dart';

/// The first thing a new account sees: not a form, a conversation.
///
/// Hearth asks how it should be with this person and what they don't
/// want, they answer in their own words, and the server turns that into
/// both a real reply and the standing rules every later prompt carries
/// (`POST /onboarding/intro`). Asking this before the screening battery
/// is the whole point — being asked twenty questions about what's wrong
/// with you before anyone has asked how you want to be spoken to is the
/// difference between an intake form and a conversation.
class OnboardingIntroChatView extends ConsumerStatefulWidget {
  /// Moves on to the screening questions — after an answer, or straight
  /// away if they'd rather not answer.
  final VoidCallback onDone;

  const OnboardingIntroChatView({super.key, required this.onDone});

  @override
  ConsumerState<OnboardingIntroChatView> createState() => _OnboardingIntroChatViewState();
}

/// Longest answer the server accepts (`MAX_INTRO_ANSWER_LEN`) — enforced
/// here too so the limit is a full field rather than a rejected request.
const _maxAnswerLength = 1200;

class _OnboardingIntroChatViewState extends ConsumerState<OnboardingIntroChatView> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  String? _answer;
  String? _reply;
  bool _sending = false;
  Object? _error;

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _input.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() {
      _answer = text;
      _sending = true;
      _error = null;
    });
    _input.clear();
    _scrollToEnd();

    try {
      final understanding = await ref.read(onboardingApiProvider).sendIntro(text);
      // The saved rules live on the profile, which the settings screen
      // and every later read of `myProfileProvider` will otherwise show
      // stale for the rest of the session.
      ref.invalidate(myProfileProvider);
      if (!mounted) return;
      setState(() {
        _reply = understanding.reply;
        _sending = false;
      });
      _scrollToEnd();
    } catch (e) {
      if (!mounted) return;
      // The text goes back in the box rather than being lost — they may
      // have written something considered, and retyping it is the last
      // thing to ask of someone in their first minute in the app.
      setState(() {
        _sending = false;
        _error = e;
        _input.text = text;
        _answer = null;
      });
    }
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final palette = AppPalette.of(context);
    final answered = _reply != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(
            onPressed: _sending ? null : widget.onDone,
            child: Text(l10n.onboardingSkipStep,
                style: AppTypography.subheadline.copyWith(color: palette.textSecondary)),
          ),
        ),
        Expanded(
          child: ListView(
            controller: _scroll,
            padding: EdgeInsets.zero,
            children: [
              const SizedBox(height: 6),
              _Bubble(text: l10n.introGreeting, fromUser: false, palette: palette),
              _Bubble(text: l10n.introQuestion, fromUser: false, palette: palette),
              if (_answer == null && !answered) ...[
                const SizedBox(height: 2),
                Text(
                  l10n.introExamples,
                  style: AppTypography.footnote.copyWith(color: palette.textTertiary, height: 1.5),
                ),
              ],
              if (_answer != null) _Bubble(text: _answer!, fromUser: true, palette: palette),
              if (_sending) _TypingBubble(palette: palette),
              if (_reply != null) _Bubble(text: _reply!, fromUser: false, palette: palette),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(friendlyErrorMessage(l10n, _error!),
                    style: AppTypography.footnote.copyWith(color: palette.warning)),
              ],
              const SizedBox(height: 10),
            ],
          ),
        ),
        if (answered) ...[
          Text(
            l10n.introChangeLater,
            textAlign: TextAlign.center,
            style: AppTypography.footnote.copyWith(color: palette.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 12),
          AppPrimaryButton(label: l10n.introContinue, onPressed: widget.onDone),
        ] else
          _Composer(
            controller: _input,
            palette: palette,
            hint: l10n.introInputHint,
            sending: _sending,
            onSend: _send,
          ),
      ],
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final AppPalette palette;
  final String hint;
  final bool sending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.palette,
    required this.hint,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: palette.glassFill,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: palette.separator),
            ),
            child: TextField(
              controller: controller,
              enabled: !sending,
              minLines: 1,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              inputFormatters: [LengthLimitingTextInputFormatter(_maxAnswerLength)],
              style: AppTypography.subheadline.copyWith(color: palette.textPrimary, height: 1.45),
              cursorColor: palette.accent,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: hint,
                hintStyle: AppTypography.subheadline.copyWith(color: palette.textTertiary),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Material(
          color: sending ? palette.separator : palette.accent,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: sending ? null : onSend,
            child: SizedBox(
              width: 46,
              height: 46,
              child: Icon(Icons.arrow_upward_rounded, color: AppPalette.of(context).onAccent, size: 21),
            ),
          ),
        ),
      ],
    );
  }
}

class _Bubble extends StatelessWidget {
  final String text;
  final bool fromUser;
  final AppPalette palette;

  const _Bubble({required this.text, required this.fromUser, required this.palette});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * (fromUser ? 0.72 : 0.84),
        ),
        decoration: BoxDecoration(
          color: fromUser ? palette.accent : palette.glassFill,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(fromUser ? 20 : 6),
            bottomRight: Radius.circular(fromUser ? 6 : 20),
          ),
          border: fromUser ? null : Border.all(color: palette.separator),
        ),
        child: Text(
          text,
          style: AppTypography.label.copyWith(
            fontWeight: FontWeight.w400,
            height: 1.55,
            color: fromUser ? AppPalette.of(context).onAccent : palette.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Three dots in an assistant bubble while the reply is being written —
/// the same "someone is answering you" signal the chat tab gives, so
/// this step reads as a conversation rather than a form submitting.
class _TypingBubble extends StatefulWidget {
  final AppPalette palette;
  const _TypingBubble({required this.palette});

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1100))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        decoration: BoxDecoration(
          color: widget.palette.glassFill,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
            bottomLeft: Radius.circular(6),
            bottomRight: Radius.circular(20),
          ),
          border: Border.all(color: widget.palette.separator),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: EdgeInsets.only(right: i == 2 ? 0 : 6),
                  child: Opacity(
                    // A triangle wave, staggered by thirds of a cycle, so
                    // the three dots pulse in sequence off one controller.
                    opacity: 0.3 +
                        0.7 * (1 - ((((_controller.value + i / 3) % 1.0) - 0.5).abs() * 2)),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: widget.palette.textTertiary,
                        shape: BoxShape.circle,
                      ),
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
