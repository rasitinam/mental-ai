import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/components.dart';
import '../../../app/theme/glass.dart';
import '../../../core/onboarding/first_run.dart';
import '../../../core/voice/voice.dart';
import '../../../l10n/app_localizations.dart';
import '../../onboarding/presentation/chat_boundaries_screen.dart';
import '../../streak/data/streak_api.dart';
import '../domain/chat_message.dart';
import 'chat_controller.dart';

class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();
  int _lastMessageCount = 0;

  void _send() {
    final text = _inputController.text;
    if (text.trim().isEmpty) return;
    _inputController.clear();
    ref.read(chatControllerProvider.notifier).send(text);
    // A message is one of the three things a day can be "active" by.
    ref.invalidate(streakProvider);
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(chatControllerProvider);
    final palette = AppPalette.of(context);
    final narrow = MediaQuery.sizeOf(context).width < 380;

    // The first reply that actually lands is worth marking, once. A reply
    // arriving appends to a transcript that ended on the person's own
    // message, and only a two-message transcript can be a first exchange.
    ref.listen(chatControllerProvider.select((s) => s.messages), (previous, next) {
      final justReplied = previous != null &&
          previous.isNotEmpty &&
          previous.last.sender == ChatSender.user &&
          next.length > previous.length &&
          next.last.sender == ChatSender.assistant;
      if (!justReplied || next.length > 2) return;

      celebrateFirst(
        context,
        ref,
        key: FirstRun.firstChat,
        icon: Icons.forum_rounded,
        title: l10n.milestoneFirstChatTitle,
        body: l10n.milestoneFirstChatBody,
      );
    });

    // Free daily chat budget hit: say why, then go to the paywall instead
    // of leaving a chat that just stopped replying.
    ref.listen(chatControllerProvider.select((s) => s.quotaExceededTick), (previous, next) {
      if (previous == null || next <= previous) return;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(l10n.chatQuotaExceeded)));
      context.push('/premium');
    });

    if (state.messages.length != _lastMessageCount) {
      _lastMessageCount = state.messages.length;
      _scrollToBottomSoon();
    }

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(l10n.navChat,
                        maxLines: 1,
                        style: AppTypography.title2.copyWith(color: palette.textPrimary)),
                  ),
                  PillButton(
                    icon: Icons.tune_rounded,
                    label: l10n.chatPreferences,
                    iconOnly: narrow,
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ChatBoundariesScreen()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const SupportPill(),
                ],
              ),
            ),
            Expanded(
              child: state.loadingHistory && state.messages.isEmpty
                  ? Center(child: CircularProgressIndicator(color: palette.textPrimary))
                  : state.messages.isEmpty
                      ? SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(22, 8, 22, 8),
                          child: Column(
                            children: [
                              FeatureIntroCard(
                                introKey: FirstRun.chatIntro,
                                icon: Icons.forum_rounded,
                                title: l10n.introChatTitle,
                                body: l10n.introChatBody,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                l10n.chatEmptyPrompt,
                                style: AppTypography.body.copyWith(color: palette.textSecondary),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                          itemCount: state.messages.length + 1,
                          itemBuilder: (context, index) {
                            if (index == 0) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Center(child: SectionLabel(l10n.chatToday, color: palette.textTertiary)),
                              );
                            }
                            return _ChatBubble(message: state.messages[index - 1]);
                          },
                        ),
            ),
            if (state.sending)
              SizedBox(
                height: 2,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  color: palette.textPrimary,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 54),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      alignment: Alignment.centerLeft,
                      decoration: BoxDecoration(
                        color: palette.glassFill,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [BoxShadow(color: palette.separator, offset: const Offset(0, 1))],
                      ),
                      child: TextField(
                        controller: _inputController,
                        onSubmitted: (_) => _send(),
                        textInputAction: TextInputAction.send,
                        minLines: 1,
                        maxLines: 5,
                        style: AppTypography.body.copyWith(color: palette.textPrimary),
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(vertical: 15),
                          hintText: l10n.chatInputHint,
                          hintStyle: AppTypography.body.copyWith(color: palette.textTertiary),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  DictationButton(controller: _inputController),
                  const SizedBox(width: 8),
                  _SendButton(onTap: _send),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final VoidCallback onTap;
  const _SendButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Tooltip(
      message: l10n.dmSend,
      child: Material(
        // Vivid rather than Sohbet's pale sky tint — the one button on this
        // screen that should read as genuinely colorful, not a pastel.
        color: palette.vividBlue,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 54,
            height: 54,
            child: Icon(Icons.arrow_forward_rounded, size: 23, color: palette.onVivid),
          ),
        ),
      ),
    );
  }
}

class _ChatBubble extends StatefulWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  State<_ChatBubble> createState() => _ChatBubbleState();
}

class _ChatBubbleState extends State<_ChatBubble> {
  // Dismissing only hides this message's own crisis card — nothing changes
  // server-side, so a later message can still surface it again.
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isUser = widget.message.sender == ChatSender.user;
    final screenWidth = MediaQuery.sizeOf(context).width;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Align(
            alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
              constraints: BoxConstraints(maxWidth: isUser ? screenWidth * 0.7 : screenWidth * 0.78),
              decoration: BoxDecoration(
                color: isUser ? palette.sky : palette.glassFill,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(22),
                  topRight: const Radius.circular(22),
                  bottomLeft: Radius.circular(isUser ? 22 : 6),
                  bottomRight: Radius.circular(isUser ? 6 : 22),
                ),
              ),
              child: isUser
                  ? Text(widget.message.text, style: AppTypography.body.copyWith(color: palette.onTint))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text.rich(
                          TextSpan(
                            children: _boldSpans(
                              widget.message.text,
                              AppTypography.body.copyWith(color: palette.textPrimary),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Transform.translate(
                          offset: const Offset(-8, 2),
                          child: SpeakButton(
                            id: 'chat-${identityHashCode(widget.message)}',
                            text: widget.message.text,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          if (widget.message.crisisFlag && !_dismissed)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: palette.warningSoft,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.support_rounded, size: 20, color: palette.warning),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          l10n.chatCrisisTitle,
                          style: AppTypography.label.copyWith(color: palette.warning, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(l10n.chatCrisis, style: AppTypography.subheadline.copyWith(color: palette.warning)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _CrisisAction(
                          label: l10n.chatCallEmergency,
                          filled: true,
                          onTap: () => launchUrl(Uri(scheme: 'tel', path: emergencyNumber)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _CrisisAction(
                          label: l10n.chatContinue,
                          filled: false,
                          onTap: () => setState(() => _dismissed = true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Splits `**bold**` runs out of the model's reply into their own spans
/// so they render bold instead of showing the literal asterisks — the
/// model writes markdown emphasis fairly often, and this is the only
/// markdown it reaches for, so a full markdown renderer would be more
/// than the case in front of it needs.
final _boldPattern = RegExp(r'\*\*(.+?)\*\*');

List<InlineSpan> _boldSpans(String text, TextStyle base) {
  final boldStyle = base.copyWith(fontWeight: FontWeight.w700);
  final spans = <InlineSpan>[];
  var last = 0;
  for (final match in _boldPattern.allMatches(text)) {
    if (match.start > last) {
      spans.add(TextSpan(text: text.substring(last, match.start), style: base));
    }
    spans.add(TextSpan(text: match.group(1), style: boldStyle));
    last = match.end;
  }
  if (last < text.length) {
    spans.add(TextSpan(text: text.substring(last), style: base));
  }
  return spans;
}

class _CrisisAction extends StatelessWidget {
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _CrisisAction({required this.label, required this.filled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);

    return Material(
      color: filled ? palette.warning : Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: filled ? BorderSide.none : BorderSide(color: palette.warning, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 46,
          alignment: Alignment.center,
          child: Text(
            label,
            style: AppTypography.label.copyWith(
              fontWeight: FontWeight.w700,
              color: filled ? palette.warningSoft : palette.warning,
            ),
          ),
        ),
      ),
    );
  }
}
