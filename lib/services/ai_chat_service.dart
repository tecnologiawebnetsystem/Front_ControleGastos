import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:controle_gasto_pessoal/models/chat_message.dart';

class AIChatService {
  // Singleton pattern
  static final AIChatService _instance = AIChatService._internal();
  factory AIChatService() => _instance;
  AIChatService._internal();

  // Configurações da API
  final String _apiUrl = 'https://api.openai.com/v1/chat/completions';
  final String _apiKey = 'sk-your-api-key'; // Substitua pela sua chave de API real
  
  // Histórico de mensagens para contexto
  final List<Map<String, String>> _messageHistory = [];
  
  // Sistema prompt para limitar o escopo da conversa
  final String _systemPrompt = '''
Você é um assistente especializado em gestão financeira pessoal e controle de gastos.
Responda apenas perguntas relacionadas a finanças pessoais, orçamento, investimentos, 
economia, dívidas, planejamento financeiro e tópicos relacionados.
Se o usuário perguntar sobre outros assuntos, educadamente redirecione a conversa 
para temas de gestão financeira.
Mantenha suas respostas concisas, práticas e úteis.
''';

  // Método para enviar uma mensagem para a API
  Future<String> sendMessage(String message) async {
    try {
      // Adicionar mensagem do usuário ao histórico
      _messageHistory.add({"role": "user", "content": message});
      
      // Preparar o corpo da requisição
      final body = jsonEncode({
        "model": "gpt-3.5-turbo",
        "messages": [
          {"role": "system", "content": _systemPrompt},
          ..._messageHistory,
        ],
        "temperature": 0.7,
        "max_tokens": 500,
      });
      
      // Configurar os headers
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_apiKey',
      };
      
      // Fazer a requisição
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: headers,
        body: body,
      );
      
      // Processar a resposta
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final assistantMessage = jsonResponse['choices'][0]['message']['content'];
        
        // Adicionar resposta ao histórico
        _messageHistory.add({"role": "assistant", "content": assistantMessage});
        
        return assistantMessage;
      } else {
        if (kDebugMode) {
          print('Erro na API: ${response.statusCode} - ${response.body}');
        }
        return _getErrorMessage(response.statusCode);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Exceção ao enviar mensagem: $e');
      }
      return 'Desculpe, ocorreu um erro ao processar sua mensagem. Por favor, tente novamente mais tarde.';
    }
  }
  
  // Método para simular resposta em modo de desenvolvimento
  Future<String> simulateResponse(String message) async {
    // Simular um atraso de rede
    await Future.delayed(Duration(seconds: 1));
    
    // Verificar se a mensagem está relacionada a finanças
    if (_isFinanceRelated(message)) {
      return _getFinanceResponse(message);
    } else {
      return 'Sou especializado em gestão financeira pessoal. Posso ajudar você com orçamento, investimentos, economia, dívidas ou planejamento financeiro. Como posso auxiliar com suas finanças hoje?';
    }
  }
  
  // Método para verificar se a mensagem está relacionada a finanças
  bool _isFinanceRelated(String message) {
    final financeKeywords = [
      'dinheiro', 'finança', 'financeira', 'orçamento', 'gasto', 'despesa',
      'receita', 'investimento', 'economia', 'poupança', 'dívida', 'empréstimo',
      'cartão', 'crédito', 'débito', 'banco', 'conta', 'salário', 'renda',
      'juros', 'imposto', 'taxa', 'aplicação', 'ação', 'bolsa', 'mercado',
      'financeiro', 'economizar', 'poupar', 'gastar', 'comprar', 'vender',
      'preço', 'custo', 'valor', 'pagamento', 'fatura', 'recibo', 'nota',
      'fiscal', 'contabilidade', 'planejamento', 'meta', 'objetivo', 'futuro',
      'aposentadoria', 'reserva', 'emergência', 'seguro', 'investir', 'guardar'
    ];
    
    final lowerMessage = message.toLowerCase();
    return financeKeywords.any((keyword) => lowerMessage.contains(keyword));
  }
  
  // Método para obter uma resposta simulada relacionada a finanças
  String _getFinanceResponse(String message) {
    final lowerMessage = message.toLowerCase();
    
    if (lowerMessage.contains('orçamento') || lowerMessage.contains('orcamento')) {
      return 'Criar um orçamento é o primeiro passo para uma gestão financeira eficaz. Recomendo dividir suas despesas em categorias essenciais (moradia, alimentação, transporte) e não essenciais (lazer, assinaturas). Acompanhe seus gastos diariamente e compare com o orçamento planejado no final do mês.';
    } else if (lowerMessage.contains('investimento') || lowerMessage.contains('investir')) {
      return 'Para começar a investir, primeiro estabeleça uma reserva de emergência equivalente a 3-6 meses de despesas. Depois, diversifique seus investimentos de acordo com seus objetivos e perfil de risco. Lembre-se: quanto maior o retorno potencial, maior o risco.';
    } else if (lowerMessage.contains('dívida') || lowerMessage.contains('divida')) {
      return 'Para quitar dívidas, recomendo o método bola de neve: liste todas as dívidas, pague o mínimo em todas e direcione o máximo possível para a de maior juros. Quando quitar uma, direcione o valor para a próxima. Negocie taxas menores sempre que possível.';
    } else if (lowerMessage.contains('economizar') || lowerMessage.contains('poupar')) {
      return 'Para economizar dinheiro, adote a regra 50-30-20: 50% da renda para necessidades básicas, 30% para desejos e 20% para poupança e investimentos. Automatize transferências para sua conta de poupança no dia do pagamento e revise despesas recorrentes regularmente.';
    } else {
      return 'Gestão financeira pessoal envolve planejar, organizar e controlar seus recursos financeiros. Comece estabelecendo metas claras, criando um orçamento realista e acompanhando seus gastos. Posso ajudar com dicas específicas sobre orçamento, investimentos, dívidas ou economia. O que você gostaria de saber?';
    }
  }
  
  // Método para obter mensagem de erro baseada no código de status
  String _getErrorMessage(int statusCode) {
    switch (statusCode) {
      case 401:
        return 'Erro de autenticação. Por favor, verifique as configurações da API.';
      case 429:
        return 'Muitas requisições em pouco tempo. Por favor, aguarde um momento e tente novamente.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Serviço temporariamente indisponível. Por favor, tente novamente mais tarde.';
      default:
        return 'Ocorreu um erro ao processar sua solicitação. Por favor, tente novamente.';
    }
  }
  
  // Método para limpar o histórico de mensagens
  void clearHistory() {
    _messageHistory.clear();
  }
}

