import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_prefs.dart';
import '../data/chat_api.dart';
import '../domain/chat_message.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool sending;
  final bool loadingHistory;
  final Object? error;

  const ChatState({
    this.messages = const [],
    this.sending = false,
    this.loadingHistory = true,
    this.error,
  });

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? sending,
    bool? loadingHistory,
    Object? error,
  }) =>
      ChatState(
        messages: messages ?? this.messages,
        sending: sending ?? this.sending,
        loadingHistory: loadingHistory ?? this.loadingHistory,
        error: error,
      );
}

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(ChatController.new);

class ChatController extends Notifier<ChatState> {
  @override
  ChatState build() {
    // Watched (not read): a login/logout/account switch changes this and
    // should reset the thread to that account's own history rather than
    // keep showing whoever was signed in before.
    ref.watch(sessionTokenProvider);
    Future.microtask(_loadHistory);
    return const ChatState();
  }

  Future<void> _loadHistory() async {
    try {
      final history = await ref.read(chatApiProvider).history();
      state = state.copyWith(messages: history, loadingHistory: false);
    } catch (_) {
      // Not fatal — the person can still chat, they just won't see older
      // turns until the next successful load (e.g. pulling to refresh the
      // screen, or the next app start).
      state = state.copyWith(loadingHistory: false);
    }
  }

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;

    // Captured before appending the new message, so it's exactly "the
    // transcript so far" — what the backend needs to answer as a
    // continuation instead of a fresh, memoryless reply.
    final historyBeforeThisTurn = state.messages;

    final userMessage = ChatMessage(sender: ChatSender.user, text: text.trim());
    state = state.copyWith(messages: [...state.messages, userMessage], sending: true, error: null);

    try {
      final reply = await ref.read(chatApiProvider).sendMessage(
            message: text.trim(),
            history: historyBeforeThisTurn,
          );
      final assistantMessage = ChatMessage(
        sender: ChatSender.assistant,
        text: reply.reply,
        crisisFlag: reply.crisisFlag,
      );
      state = state.copyWith(messages: [...state.messages, assistantMessage], sending: false);
    } catch (e) {
      state = state.copyWith(sending: false, error: e);
    }
  }
}
