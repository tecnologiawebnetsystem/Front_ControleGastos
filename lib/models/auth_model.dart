import 'package:flutter/foundation.dart';

class AuthResponse {
  final bool success;
  final String? message;
  final String? token;
  final Map<String, dynamic>? userData;

  AuthResponse({
    required this.success,
    this.message,
    this.token,
    this.userData,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Adicionar logs para depuração
    if (kDebugMode) {
      print('Processando resposta de autenticação: $json');
    }

    // Tentar extrair o token de diferentes locais possíveis na resposta
    String? token = json['token'];
    if (token == null && json['data'] != null) {
      if (json['data'] is Map) {
        token = json['data']['token'];
      }
    }

    // Tentar extrair os dados do usuário
    Map<String, dynamic>? userData;
    if (json['data'] != null && json['data'] is Map) {
      userData = Map<String, dynamic>.from(json['data']);

      // Adicionar log para verificar os dados do usuário
      if (kDebugMode) {
        print('Dados do usuário extraídos de data: $userData');
      }
    } else if (json['user'] != null && json['user'] is Map) {
      userData = Map<String, dynamic>.from(json['user']);

      // Adicionar log para verificar os dados do usuário
      if (kDebugMode) {
        print('Dados do usuário extraídos de user: $userData');
      }
    } else if (json['usuario'] != null && json['usuario'] is Map) {
      userData = Map<String, dynamic>.from(json['usuario']);

      // Adicionar log para verificar os dados do usuário
      if (kDebugMode) {
        print('Dados do usuário extraídos de usuario: $userData');
      }
    }

    // Se não encontramos dados do usuário, mas temos um token, criar um objeto básico
    if (userData == null && token != null) {
      userData = {
        'id': 0,
        'nome': 'Usuário',
        'email': '',
        'login': '',
        'adm': false,
        'ativo': true,
      };

      if (kDebugMode) {
        print('Dados do usuário criados manualmente: $userData');
      }
    }

    // Determinar o sucesso com base na presença do token e na mensagem
    // Se temos um token e uma mensagem positiva, consideramos como sucesso
    bool isSuccess = json['success'] ?? false;
    if (!isSuccess &&
        token != null &&
        (json['message'] == 'Login bem-sucedido' || json['message'] == null)) {
      isSuccess = true;
    }

    return AuthResponse(
      success: isSuccess,
      message: json['message'],
      token: token,
      userData: userData,
    );
  }

  @override
  String toString() {
    return 'AuthResponse{success: $success, message: $message, token: ${token != null ? '***' : 'null'}, userData: $userData}';
  }
}

class AuthRequest {
  final String email;
  final String password;

  AuthRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'senha': password,
    };
  }
}
