import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../domain/chat_message.dart';

final chatApiProvider = Provider<ChatApi>((ref) => ChatApi(ref.watch(apiClientProvider)));

class ChatReply {
  final String reply;
  final bool crisisFlag;
  const ChatReply({required this.reply, required this.crisisFlag});
}

class ChatApi {
  final Dio _dio;
  ChatApi(this._dio);

  /// `history` is the transcript so far (oldest first, not including
  /// `message`) — the backend has no session store, so this is what
  /// gives the model actual conversational memory turn to turn. Only the
  /// last 16 matter to the backend anyway, but there's no reason to ship
  /// more than that over the wire either.
  Future<ChatReply> sendMessage({
    required String userId,
    required String message,
    List<ChatMessage> history = const [],
  }) async {
    final trimmed = history.length > 16 ? history.sublist(history.length - 16) : history;

    final response = await _dio.post('/chat', data: {
      'user_id': userId,
      'message': message,
      'history': [
        for (final m in trimmed)
          {'role': m.sender == ChatSender.user ? 'user' : 'assistant', 'content': m.text},
      ],
    });

    return ChatReply(
      reply: response.data['reply'] as String,
      crisisFlag: response.data['crisis_flag'] as bool? ?? false,
    );
  }
}
