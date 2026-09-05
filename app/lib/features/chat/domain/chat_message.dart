enum ChatSender { user, assistant }

class ChatMessage {
  final ChatSender sender;
  final String text;
  final bool crisisFlag;

  const ChatMessage({required this.sender, required this.text, this.crisisFlag = false});
}
