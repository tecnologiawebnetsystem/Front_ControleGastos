import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:controle_gasto_pessoal/config/environment.dart';
import 'dart:async';

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
    if (kDebugMode) {
      print(
          'Token definido no ApiService: ${token != null ? token.substring(0, min(10, token.length)) + '...' : 'null'}');
    }
  }

  // Getter para o token de autenticação
  String? get authToken => _authToken;

  // Método para obter os headers com o token de autenticação (se disponível)
  Map<String, String> get _getHeaders {
    final headers = Map<String, String>.from(_headers);
    if (_authToken != null) {
      headers['Authorization'] = 'Bearer $_authToken';
      if (kDebugMode) {
        print('Adicionando token de autorização ao header');
      }
    } else {
      if (kDebugMode) {
        print('AVISO: Token de autorização não disponível');
      }
    }
    return headers;
  }

  // Método GET
  Future<dynamic> get(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');

      if (kDebugMode) {
        print('GET: $url');
        print('Headers: $_getHeaders');
      }

      final response = await http
          .get(
        url,
        headers: _getHeaders,
      )
          .timeout(Duration(seconds: 30), onTimeout: () {
        if (kDebugMode) {
          print('Timeout na requisição GET para $url');
        }
        throw TimeoutException('A requisição excedeu o tempo limite');
      });

      return _processResponse(response);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Método POST
  Future<dynamic> post(String endpoint, dynamic data) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final body = json.encode(data);

      if (kDebugMode) {
        print('POST: $url');
        print('Headers: $_getHeaders');
        print('Data: $body');
      }

      final response = await http
          .post(
        url,
        headers: _getHeaders,
        body: body,
      )
          .timeout(Duration(seconds: 30), onTimeout: () {
        if (kDebugMode) {
          print('Timeout na requisição POST para $url');
        }
        throw TimeoutException('A requisição excedeu o tempo limite');
      });

      return _processResponse(response);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Método PUT
  Future<dynamic> put(String endpoint, dynamic data) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');
      final body = json.encode(data);

      if (kDebugMode) {
        print('PUT: $url');
        print('Headers: $_getHeaders');
        print('Data: $body');
      }

      final response = await http
          .put(
        url,
        headers: _getHeaders,
        body: body,
      )
          .timeout(Duration(seconds: 30), onTimeout: () {
        if (kDebugMode) {
          print('Timeout na requisição PUT para $url');
        }
        throw TimeoutException('A requisição excedeu o tempo limite');
      });

      return _processResponse(response);
    } catch (e) {
      _handleError(e);
      rethrow;
    }
  }

  // Método DELETE
  Future<dynamic> delete(String endpoint) async {
    try {
      final url = Uri.parse('$baseUrl/$endpoint');

      if (kDebugMode) {
        print('DELETE: $url');
        print('Headers: $_getHeaders');
      }

      final response = await http
          .delete(
        url,
        headers: _getHeaders,
      )
          .timeout(Duration(seconds: 30), onTimeout: () {
        if (kDebugMode) {
          print('Timeout na requisição DELETE para $url');
        }
        throw TimeoutException('A requisição excedeu o tempo limite');
      });

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
      if (response.body.isNotEmpty) {
        final body = json.decode(response.body);
        message = body['message'] ?? body['error'] ?? 'Erro desconhecido';
      }
    } catch (e) {
      message = response.body.isNotEmpty ? response.body : 'Erro desconhecido';
    }

    if (kDebugMode) {
      print('Erro HTTP $statusCode: $message');
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
      print('Tipo de erro: ${error.runtimeType}');
      if (error is Error) {
        print('Stack trace: ${error.stackTrace}');
      }
    }
  }

  // Função auxiliar para limitar o tamanho de uma string
  int min(int a, int b) {
    return a < b ? a : b;
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
