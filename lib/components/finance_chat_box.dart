import 'package:flutter/material.dart';
import 'package:controle_gasto_pessoal/models/chat_message.dart';
import 'package:controle_gasto_pessoal/services/ai_chat_service.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'dart:math' show sin;

class FinanceChatBox extends StatefulWidget {
  const FinanceChatBox({Key? key}) : super(key: key);

  @override
  _FinanceChatBoxState createState() => _FinanceChatBoxState();
}

class _FinanceChatBoxState extends State<FinanceChatBox>
    with SingleTickerProviderStateMixin {
  final List<ChatMessage> _messages = [];
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AIChatService _chatService = AIChatService();
  final DateFormat _timeFormat = DateFormat('HH:mm');

  bool _isOpen = false;
  bool _isTyping = false;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    // Configurar animação
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    // Adicionar mensagem de boas-vindas
    _messages.add(ChatMessage.assistant(
        'Olá! Sou seu assistente de gestão financeira pessoal. Como posso ajudar você a controlar melhor suas finanças hoje?'));
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() {
      _isOpen = !_isOpen;
      if (_isOpen) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  void _handleSubmit(String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();

    // Adicionar mensagem do usuário
    setState(() {
      _messages.add(ChatMessage.user(text));
      _messages.add(ChatMessage.loading());
      _isTyping = true;
    });

    // Rolar para o final da lista
    _scrollToBottom();

    // Obter resposta da IA
    String response;
    if (kDebugMode) {
      // Em modo de desenvolvimento, usar resposta simulada
      response = await _chatService.simulateResponse(text);
    } else {
      // Em produção, usar API real
      response = await _chatService.sendMessage(text);
    }

    // Atualizar mensagens
    setState(() {
      // Remover mensagem de carregamento
      _messages.removeLast();
      // Adicionar resposta da IA
      _messages.add(ChatMessage.assistant(response));
      _isTyping = false;
    });

    // Rolar para o final da lista
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 16,
      bottom: 16,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Chat expandido
          SizeTransition(
            sizeFactor: _animation,
            axis: Axis.vertical,
            child: Container(
              width: 320,
              height: 450,
              margin: EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Color(0xFF374151),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Cabeçalho do chat
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFF111827),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet,
                          color: Colors.blue,
                          size: 24,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Assistente Financeiro',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Spacer(),
                        IconButton(
                          icon: Icon(Icons.close, color: Colors.white),
                          onPressed: _toggleChat,
                          padding: EdgeInsets.zero,
                          constraints: BoxConstraints(),
                        ),
                      ],
                    ),
                  ),

                  // Lista de mensagens
                  Expanded(
                    child: Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: ListView.builder(
                        controller: _scrollController,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          return _buildMessageItem(message);
                        },
                      ),
                    ),
                  ),

                  // Campo de entrada
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF1F2937),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                        bottomRight: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _textController,
                            decoration: InputDecoration(
                              hintText: 'Digite sua pergunta...',
                              hintStyle: TextStyle(color: Colors.white70),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(20),
                                borderSide: BorderSide.none,
                              ),
                              filled: true,
                              fillColor: Color(0xFF374151),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                            ),
                            style: TextStyle(color: Colors.white),
                            maxLines: 1,
                            onSubmitted: _handleSubmit,
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: Icon(
                              Icons.send,
                              color: Colors.white,
                            ),
                            onPressed: () =>
                                _handleSubmit(_textController.text),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Botão para abrir o chat
          FloatingActionButton(
            onPressed: _toggleChat,
            backgroundColor: Colors.blue,
            child: Icon(
              _isOpen ? Icons.close : Icons.chat,
              color: Colors.white,
            ),
            tooltip: _isOpen ? 'Fechar chat' : 'Abrir assistente financeiro',
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(ChatMessage message) {
    switch (message.type) {
      case MessageType.user:
        return _buildUserMessage(message);
      case MessageType.assistant:
        return _buildAssistantMessage(message);
      case MessageType.loading:
        return _buildLoadingMessage();
      default:
        return SizedBox.shrink();
    }
  }

  Widget _buildUserMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: 240,
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 4),
              Text(
                _timeFormat.format(message.timestamp),
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
          SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.blue.shade800,
            radius: 16,
            child: Icon(
              Icons.person,
              color: Colors.white,
              size: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssistantMessage(ChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.shade800,
            radius: 16,
            child: Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 16,
            ),
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                constraints: BoxConstraints(
                  maxWidth: 240,
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Color(0xFF1F2937),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  message.text,
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(height: 4),
              Text(
                _timeFormat.format(message.timestamp),
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMessage() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor: Colors.green.shade800,
            radius: 16,
            child: Icon(
              Icons.account_balance_wallet,
              color: Colors.white,
              size: 16,
            ),
          ),
          SizedBox(width: 8),
          Container(
            constraints: BoxConstraints(
              maxWidth: 240,
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDot(0),
                _buildDot(1),
                _buildDot(2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          final delay = index * 0.2;
          final sinValue =
              sin((_animationController.value * 2 * 3.14159) + delay);
          final size = 4.0 + (sinValue + 1) * 2;

          return Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          );
        },
      ),
    );
  }
}
