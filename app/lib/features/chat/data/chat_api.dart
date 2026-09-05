import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

final chatApiProvider = Provider<ChatApi>((ref) => ChatApi(ref.watch(apiClientProvider)));

class ChatReply {
  final String reply;
  final bool crisisFlag;
  const ChatReply({required this.reply, required this.crisisFlag});
}

class ChatApi {
  final Dio _dio;
  ChatApi(this._dio);

  Future<ChatReply> sendMessage({required String userId, required String message}) async {
    final response = await _dio.post('/chat', data: {'user_id': userId, 'message': message});
    return ChatReply(
      reply: response.data['reply'] as String,
      crisisFlag: response.data['crisis_flag'] as bool? ?? false,
    );
  }
}
