import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';
import '../../../app/theme/glass.dart';
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
      appBar: AppBar(title: const Text('Sohbet')),
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
                            'Bir şey paylaşmak ister misin?',
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
                blurSigma: 24,
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
                          hintText: 'Bir şey yaz...',
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

class _ChatBubble extends StatelessWidget {
  final ChatMessage message;
  const _ChatBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final isUser = message.sender == ChatSender.user;

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
              message.text,
              style: AppTypography.body.copyWith(color: isUser ? Colors.white : palette.textPrimary),
            ),
          ),
        ),
        if (message.crisisFlag)
          Container(
            margin: const EdgeInsets.only(bottom: 10, top: 2),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: palette.warningSoft,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'Zor bir an gibi görünüyor. Acil durumdaysan 112\'yi ara; '
              'konuşmak istersen bir uzmana ulaşmayı düşünebilirsin.',
              style: AppTypography.subheadline.copyWith(color: palette.warning),
            ),
          ),
      ],
    );
  }
}
