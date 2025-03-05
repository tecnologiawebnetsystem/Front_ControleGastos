import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:controle_gasto_pessoal/config/environment.dart';

class ApiService {
  // URL base da API obtida da configuração de ambiente
  static final String baseUrl = AppConfig.apiBaseUrl;

  // Headers padrão para as requisições
  static final Map<String, String> _headers = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  // Token de autenticação (se necessário)
  String? _authToken;

  // Setter para o token de autenticação
  set authToken(String? token) {
    _authToken = token;
  }

  // Método para obter os headers com o token de autenticação (se disponível)
  Map<String, String> get _getHeaders {
    final headers = Map<String, String>.from(_headers);
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // Método GET
  Future<dynamic> get(String endpoint) async {
    try {
      if (kDebugMode) {
        print('GET: $baseUrl/$endpoint');
      }

      final response = await http.get(
        Uri.parse('$baseUrl/$endpoint'),
        headers: _getHeaders,
      );

      return _processResponse(response);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Método POST
  Future<dynamic> post(String endpoint, dynamic data) async {
    try {
      if (kDebugMode) {
        print('POST: $baseUrl/$endpoint');
        print('Data: ${json.encode(data)}');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/$endpoint'),
        headers: _getHeaders,
        body: json.encode(data),
      );

      return _processResponse(response);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Método PUT
  Future<dynamic> put(String endpoint, dynamic data) async {
    try {
      if (kDebugMode) {
        print('PUT: $baseUrl/$endpoint');
        print('Data: ${json.encode(data)}');
      }

      final response = await http.put(
        Uri.parse('$baseUrl/$endpoint'),
        headers: _getHeaders,
        body: json.encode(data),
      );

      return _processResponse(response);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Método DELETE
  Future<dynamic> delete(String endpoint) async {
    try {
      if (kDebugMode) {
        print('DELETE: $baseUrl/$endpoint');
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/$endpoint'),
        headers: _getHeaders,
      );

      return _processResponse(response);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Método para processar a resposta da API
  dynamic _processResponse(http.Response response) {
    if (kDebugMode) {
      print('Status Code: ${response.statusCode}');
      print('Response: ${response.body}');
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      // Verifica se o corpo da resposta está vazio
      if (response.body.isEmpty) {
        return null;
      }

      // Tenta fazer o parse do JSON
      try {
        return json.decode(response.body);
      } catch (e) {
        return response.body;
      }
    } else {
      _handleHttpError(response);
    }
  }

  // Método para lidar com erros HTTP
  void _handleHttpError(http.Response response) {
    final statusCode = response.statusCode;
    String message = 'Erro desconhecido';

    try {
      final body = json.decode(response.body);
      message = body['message'] ?? body['error'] ?? 'Erro desconhecido';
    } catch (e) {
      message = response.body;
    }

    switch (statusCode) {
      case 400:
        throw BadRequestException(message);
      case 401:
        throw UnauthorizedException(message);
      case 403:
        throw ForbiddenException(message);
      case 404:
        throw NotFoundException(message);
      case 500:
        throw ServerException(message);
      default:
        throw ApiException('Erro $statusCode: $message');
    }
  }

  // Método para lidar com erros gerais
  void _handleError(dynamic error) {
    if (kDebugMode) {
      print('Erro na API: $error');
    }
  }
}

// Exceções personalizadas
class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

class BadRequestException extends ApiException {
  BadRequestException(String message) : super(message);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(String message) : super(message);
}

class ForbiddenException extends ApiException {
  ForbiddenException(String message) : super(message);
}

class NotFoundException extends ApiException {
  NotFoundException(String message) : super(message);
}

class ServerException extends ApiException {
  ServerException(String message) : super(message);
}
