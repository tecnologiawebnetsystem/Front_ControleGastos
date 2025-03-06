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
    } else if (json['user'] != null && json['user'] is Map) {
      userData = Map<String, dynamic>.from(json['user']);
    }

    // Determinar o sucesso com base na presença do token e na mensagem
    // Se temos um token e uma mensagem positiva, consideramos como sucesso
    bool isSuccess = json['success'] ?? false;
    if (!isSuccess &&
        token != null &&
        json['message'] == 'Login bem-sucedido') {
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
