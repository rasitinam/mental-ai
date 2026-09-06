enum ChatSender { user, assistant }

class ChatMessage {
  final ChatSender sender;
  final String text;
  final bool crisisFlag;

  const ChatMessage({required this.sender, required this.text, this.crisisFlag = false});

  /// Parses one row from `GET /chat/history` (mirrors
  /// `mental_domain::ChatMessageRecord`), used to rehydrate the visible
  /// transcript on login/app start.
  factory ChatMessage.fromRecordJson(Map<String, dynamic> json) => ChatMessage(
        sender: json['role'] == 'assistant' ? ChatSender.assistant : ChatSender.user,
        text: json['content'] as String,
        crisisFlag: json['crisis_flag'] as bool? ?? false,
      );
}
