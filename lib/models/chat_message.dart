enum MessageType {
  user,
  assistant,
  loading,
}

class ChatMessage {
  final String text;
  final MessageType type;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory ChatMessage.user(String text) {
    return ChatMessage(
      text: text,
      type: MessageType.user,
    );
  }

  factory ChatMessage.assistant(String text) {
    return ChatMessage(
      text: text,
      type: MessageType.assistant,
    );
  }

  factory ChatMessage.loading() {
    return ChatMessage(
      text: '',
      type: MessageType.loading,
    );
  }
}

