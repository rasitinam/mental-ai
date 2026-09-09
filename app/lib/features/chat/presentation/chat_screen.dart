import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
import '../../../l10n/app_localizations.dart';
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
  }

  void _scrollToBottomSoon() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatControllerProvider);
    final palette = AppPalette.of(context);

    if (state.messages.length != _lastMessageCount) {
      _lastMessageCount = state.messages.length;
      _scrollToBottomSoon();
    }

    return Scaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.navChat)),
      body: Column(
        children: [
          Expanded(
            child: state.loadingHistory && state.messages.isEmpty
                ? Center(child: CircularProgressIndicator(color: palette.accent))
                : state.messages.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Text(
                            AppLocalizations.of(context)!.chatEmptyPrompt,
                            style: AppTypography.body.copyWith(color: palette.textTertiary),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) => _ChatBubble(message: state.messages[index]),
                      ),
          ),
          if (state.sending)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: SizedBox(
                height: 2,
                child: LinearProgressIndicator(
                  minHeight: 2,
                  backgroundColor: Colors.transparent,
                  color: palette.accent,
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: GlassSurface(
                radius: 26,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        onSubmitted: (_) => _send(),
                        textInputAction: TextInputAction.send,
                        style: AppTypography.body.copyWith(color: palette.textPrimary),
                        cursorColor: palette.accent,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          hintText: AppLocalizations.of(context)!.chatInputHint,
                          hintStyle: AppTypography.body.copyWith(color: palette.textTertiary),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    _SendButton(color: palette.accent, onTap: _send),
                  ],
                ),
              ),
            ),
          ),
        ],
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
        child: const Padding(
          padding: EdgeInsets.all(10),
          child: Icon(Icons.arrow_upward_rounded, size: 18, color: Colors.white),
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
    final uri = Uri(scheme: 'tel', path: _emergencyNumber);
    await launchUrl(uri);
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
            margin: const EdgeInsets.symmetric(vertical: 5),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isUser ? palette.accent : palette.glassFill,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 6),
                bottomRight: Radius.circular(isUser ? 6 : 20),
              ),
              border: isUser ? null : Border.all(color: palette.glassBorder, width: 1),
            ),
            child: Text(
              widget.message.text,
              style: AppTypography.body.copyWith(color: isUser ? Colors.white : palette.textPrimary),
            ),
          ),
        ),
        if (widget.message.crisisFlag && !_dismissed)
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 10, top: 2),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: palette.warningSoft,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.chatCrisis,
                  style: AppTypography.subheadline.copyWith(color: palette.warning),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: _call,
                        style: FilledButton.styleFrom(
                          backgroundColor: palette.warning,
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: Text(l10n.chatCallEmergency),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _dismissed = true),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: palette.warning,
                          side: BorderSide(color: palette.warning.withValues(alpha: 0.4)),
                          minimumSize: const Size.fromHeight(40),
                        ),
                        child: Text(l10n.chatContinue),
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
