import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../core/onboarding/first_run.dart';
import '../../../l10n/app_localizations.dart';
import '../../streak/data/streak_api.dart';
import '../domain/chat_message.dart';
import 'chat_controller.dart';

/// Turkey's single emergency number — not configurable per user, since
/// there's no reliable, low-risk way to infer someone's actual country
/// from inside the app.
const _emergencyNumber = '112';

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

    // The first reply that actually lands is the moment the app stops
    // being a form and starts being a conversation — worth marking, once.
    // The guards matter: a reply arriving appends to a transcript that
    // ended on the person's own message (so this can't fire on the
    // history load, which goes from empty to many at once), and a
    // two-message transcript is the only one that can be a first
    // exchange (so an account that was already chatting before this
    // existed never gets congratulated on its hundredth message).
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

    // Free daily chat budget hit (see `PremiumRequiredException`): tell the
    // person why, then send them straight to the paywall instead of
    // leaving them stuck in front of a chat that just stopped replying.
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
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l10n.navChat,
                      style: AppTypography.title3.copyWith(color: palette.textPrimary, fontSize: 20)),
                  Text(l10n.chatToday,
                      style: AppTypography.footnote.copyWith(color: palette.textSecondary)),
                ],
              ),
            ),
            Expanded(
              child: state.loadingHistory && state.messages.isEmpty
                  ? Center(child: CircularProgressIndicator(color: palette.accent))
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
                                style: AppTypography.body.copyWith(color: palette.textTertiary),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) =>
                              _ChatBubble(message: state.messages[index]),
                        ),
            ),
            if (state.sending)
              SizedBox(
                height: 2,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  color: palette.accent,
                ),
              ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 88),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Container(
                        constraints: const BoxConstraints(minHeight: 52),
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        alignment: Alignment.centerLeft,
                        decoration: BoxDecoration(
                          color: palette.glassFill,
                          borderRadius: BorderRadius.circular(26),
                          border: Border.all(color: palette.separator),
                        ),
                        child: TextField(
                          controller: _inputController,
                          onSubmitted: (_) => _send(),
                          textInputAction: TextInputAction.send,
                          style: AppTypography.label
                              .copyWith(color: palette.textPrimary, fontWeight: FontWeight.w400),
                          cursorColor: palette.accent,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                            hintText: l10n.chatInputHint,
                            hintStyle: AppTypography.label.copyWith(
                              color: palette.textTertiary,
                              fontWeight: FontWeight.w400,
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _SendButton(color: palette.accent, onTap: _send),
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

class _SendButton extends StatelessWidget {
  final Color color;
  final VoidCallback onTap;
  const _SendButton({required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: const SizedBox(
          width: 52,
          height: 52,
          child: Icon(Icons.arrow_upward_rounded, size: 20, color: Colors.white),
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
  // Dismissing only hides this message's own crisis card — it doesn't
  // change anything server-side, so scrolling away and back (or a
  // future message) can still surface it again if it's still relevant.
  bool _dismissed = false;

  Future<void> _call() async {
    await launchUrl(Uri(scheme: 'tel', path: _emergencyNumber));
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final l10n = AppLocalizations.of(context)!;
    final isUser = widget.message.sender == ChatSender.user;

    return Column(
      crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * (isUser ? 0.72 : 0.8),
            ),
            decoration: BoxDecoration(
              color: isUser ? palette.accent : palette.glassFill,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 6),
                bottomRight: Radius.circular(isUser ? 6 : 20),
              ),
              border: isUser ? null : Border.all(color: palette.separator),
            ),
            child: Text(
              widget.message.text,
              style: AppTypography.label.copyWith(
                fontWeight: FontWeight.w400,
                height: 1.55,
                color: isUser ? Colors.white : palette.textPrimary,
              ),
            ),
          ),
        ),
        if (widget.message.crisisFlag && !_dismissed)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: palette.warningSoft,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: palette.warning.withValues(alpha: 0.35)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 18,
                      height: 18,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: palette.warning, shape: BoxShape.circle),
                      child: Text('!',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            color: palette.warningSoft,
                          )),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        l10n.chatCrisisTitle,
                        style: AppTypography.footnote.copyWith(
                          color: palette.warning,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.chatCrisis,
                  style: AppTypography.footnote.copyWith(color: palette.warning),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _CrisisAction(
                        label: l10n.chatCallEmergency,
                        filled: true,
                        palette: palette,
                        onTap: _call,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _CrisisAction(
                        label: l10n.chatContinue,
                        filled: false,
                        palette: palette,
                        onTap: () => setState(() => _dismissed = true),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CrisisAction extends StatelessWidget {
  final String label;
  final bool filled;
  final AppPalette palette;
  final VoidCallback onTap;

  const _CrisisAction({
    required this.label,
    required this.filled,
    required this.palette,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? palette.warning : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          decoration: filled
              ? null
              : BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: palette.warning.withValues(alpha: 0.45)),
                ),
          child: Text(
            label,
            style: AppTypography.footnote.copyWith(
              fontSize: 13.5,
              fontWeight: filled ? FontWeight.w600 : FontWeight.w500,
              color: filled ? palette.warningSoft : palette.warning,
            ),
          ),
        ),
      ),
    );
  }
}
