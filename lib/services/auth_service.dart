import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:controle_gasto_pessoal/models/auth_model.dart';
import 'package:controle_gasto_pessoal/services/api_service.dart';
import 'package:controle_gasto_pessoal/config/environment.dart';

class AuthService {
  final ApiService _apiService = ApiService();

  // Armazenamento em memória
  String? _token;
  Map<String, dynamic>? _userData;

  // Método para fazer login
  Future<AuthResponse> login(String email, String password) async {
    // Em modo de desenvolvimento, use autenticação simulada
    if (AppConfig.isDevelopment && kIsWeb) {
      return _mockLogin(email, password);
    }

    try {
      final authRequest = AuthRequest(email: email, password: password);

      final response =
          await _apiService.post('auth/login', authRequest.toJson());

      if (kDebugMode) {
        print('Resposta bruta do servidor: $response');
      }

      // Verificar se a resposta é válida
      if (response == null) {
        return AuthResponse(
          success: false,
          message: 'Resposta vazia do servidor',
        );
      }

      // Tentar extrair os dados da resposta
      AuthResponse authResponse;
      try {
        authResponse = AuthResponse.fromJson(response);
      } catch (e) {
        if (kDebugMode) {
          print('Erro ao processar resposta: $e');
        }

        // Tentar criar uma resposta a partir de um formato diferente
        bool success = response['success'] ?? false;
        String? token = response['token'] ?? response['data']?['token'];
        Map<String, dynamic>? userData = response['data'] ?? response['user'];

        authResponse = AuthResponse(
          success: success,
          message: response['message'] ?? 'Formato de resposta desconhecido',
          token: token,
          userData: userData,
        );
      }

      if (authResponse.success && authResponse.token != null) {
        // Salvar o token e os dados do usuário
        _token = authResponse.token;
        _userData = authResponse.userData;

        // Configurar o token no ApiService para futuras requisições
        _apiService.authToken = authResponse.token;

        if (kDebugMode) {
          print('Token salvo: $_token');
          print('Dados do usuário: $_userData');
        }
      }

      return authResponse;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao fazer login: $e');
      }
      return AuthResponse(
        success: false,
        message: 'Erro ao fazer login: $e',
      );
    }
  }

  // Método de login simulado para desenvolvimento
  Future<AuthResponse> _mockLogin(String email, String password) async {
    // Simular um atraso de rede
    await Future.delayed(Duration(seconds: 1));

    if (kDebugMode) {
      print('Usando login simulado para: $email');
    }

    // Aceitar qualquer credencial em modo de desenvolvimento
    final token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
    final userData = {
      'id': 1,
      'nome': 'Usuário Teste',
      'email': email,
    };

    // Salvar o token e os dados do usuário
    _token = token;
    _userData = userData;

    // Configurar o token no ApiService para futuras requisições
    _apiService.authToken = token;

    return AuthResponse(
      success: true,
      message: 'Login simulado bem-sucedido',
      token: token,
      userData: userData,
    );
  }

  // Método para verificar se o usuário está autenticado
  bool isAuthenticated() {
    return _token != null;
  }

  // Método para obter o token salvo
  String? getToken() {
    return _token;
  }

  // Método para obter os dados do usuário
  Map<String, dynamic>? getUserData() {
    return _userData;
  }

  // Método para fazer logout
  void logout() {
    _token = null;
    _userData = null;
    _apiService.authToken = null;
  }
}
