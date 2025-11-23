// lib/models/ai_message.dart
class AiMessage {  // Rename _AiMessage to AiMessage
  final bool isUser;
  final String text;

  AiMessage(this.isUser, this.text);

  // Create a message from the user
  factory AiMessage.fromUser(String text) => AiMessage(true, text);

  // Create a message from the bot
  factory AiMessage.fromBot(String text) => AiMessage(false, text);
}
