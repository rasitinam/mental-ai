import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/storage/local_prefs.dart';
import '../data/chat_api.dart';
import '../domain/chat_message.dart';

class ChatState {
  final List<ChatMessage> messages;
  final bool sending;
  final String? error;

  const ChatState({this.messages = const [], this.sending = false, this.error});

  ChatState copyWith({List<ChatMessage>? messages, bool? sending, String? error}) => ChatState(
        messages: messages ?? this.messages,
        sending: sending ?? this.sending,
        error: error,
      );
}

final chatControllerProvider = NotifierProvider<ChatController, ChatState>(ChatController.new);

class ChatController extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState();

  Future<void> send(String text) async {
    if (text.trim().isEmpty) return;

    // Captured before appending the new message, so it's exactly "the
    // transcript so far" — what the backend needs to answer as a
    // continuation instead of a fresh, memoryless reply.
    final historyBeforeThisTurn = state.messages;

    final userMessage = ChatMessage(sender: ChatSender.user, text: text.trim());
    state = state.copyWith(messages: [...state.messages, userMessage], sending: true, error: null);

    try {
      final userId = ref.read(currentUserIdProvider);
      final reply = await ref.read(chatApiProvider).sendMessage(
            userId: userId,
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
      state = state.copyWith(sending: false, error: e.toString());
    }
  }
}
