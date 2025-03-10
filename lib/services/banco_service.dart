import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:controle_gasto_pessoal/models/banco_model.dart';
import 'package:controle_gasto_pessoal/config/environment.dart';
import 'package:flutter/foundation.dart';

class BancoService {
  final String token;

  BancoService({required this.token});

  // Obter a URL base da API
  String get baseUrl => AppConfig.apiBaseUrl;

  Future<List<BancoModel>> getBancos(int usuarioId) async {
    // Verificar a URL base para garantir que está correta
    if (kDebugMode) {
      print('URL Base da API: $baseUrl');
      print('Fazendo requisição GET para: $baseUrl/bancos');
      print(
          'Token: ${token.substring(0, 10)}...'); // Mostra apenas o início do token por segurança
    }

    try {
      // Tentar com e sem o prefixo /api
      final urls = [
        '$baseUrl/bancos',
        '$baseUrl/api/bancos',
      ];

      List<BancoModel> bancos = [];
      bool success = false;

      for (var url in urls) {
        if (kDebugMode) {
          print('Tentando URL: $url');
        }

        try {
          final response = await http.get(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (kDebugMode) {
            print('Status code para $url: ${response.statusCode}');
            print('Resposta para $url: ${response.body}');
          }

          if (response.statusCode == 200) {
            final List<dynamic> data = json.decode(response.body);
            bancos = data
                .map((json) => BancoModel.fromJson(json))
                .where((banco) => banco.usuarioId == usuarioId)
                .toList();

            success = true;
            if (kDebugMode) {
              print('Sucesso com URL: $url');
              print('Bancos encontrados: ${bancos.length}');
            }
            break;
          }
        } catch (e) {
          if (kDebugMode) {
            print('Erro ao tentar $url: $e');
          }
        }
      }

      if (success) {
        return bancos;
      } else {
        if (kDebugMode) {
          print('Nenhuma URL funcionou. Retornando lista vazia.');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro geral na requisição: $e');
      }
      return [];
    }
  }

  Future<BancoModel> createBanco(BancoModel banco) async {
    // Verificar a URL base para garantir que está correta
    if (kDebugMode) {
      print('URL Base da API: $baseUrl');
      print('Fazendo requisição POST para: $baseUrl/bancos');
      print('Dados: ${json.encode(banco.toJson())}');
    }

    try {
      // Tentar com e sem o prefixo /api
      final urls = [
        '$baseUrl/bancos',
        '$baseUrl/api/bancos',
      ];

      for (var url in urls) {
        if (kDebugMode) {
          print('Tentando URL: $url');
        }

        try {
          final response = await http.post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(banco.toJson()),
          );

          if (kDebugMode) {
            print('Status code para $url: ${response.statusCode}');
            print('Resposta para $url: ${response.body}');
          }

          if (response.statusCode == 201 || response.statusCode == 200) {
            if (kDebugMode) {
              print('Sucesso com URL: $url');
            }
            return BancoModel.fromJson(json.decode(response.body));
          }
        } catch (e) {
          if (kDebugMode) {
            print('Erro ao tentar $url: $e');
          }
        }
      }

      throw Exception('Falha ao criar banco: nenhuma URL funcionou');
    } catch (e) {
      if (kDebugMode) {
        print('Erro geral na requisição: $e');
      }
      throw Exception('Erro ao criar banco: $e');
    }
  }

// Modificar o método updateBanco para incluir mais logs e verificar a resposta com mais detalhes

  Future<BancoModel> updateBanco(BancoModel banco) async {
    // Verificar a URL base para garantir que está correta
    if (kDebugMode) {
      print('URL Base da API: $baseUrl');
      print('Fazendo requisição PUT para: $baseUrl/bancos/${banco.bancoId}');
      print('Dados enviados: ${json.encode(banco.toJson())}');
    }

    try {
      // Tentar com e sem o prefixo /api e com diferentes métodos HTTP
      final endpoints = [
        '$baseUrl/bancos/${banco.bancoId}',
        '$baseUrl/api/bancos/${banco.bancoId}',
        '$baseUrl/bancos',
        '$baseUrl/api/bancos',
      ];

      // Tentar diferentes métodos HTTP
      for (var endpoint in endpoints) {
        // Tentar com PUT
        try {
          if (kDebugMode) {
            print('Tentando PUT para: $endpoint');
          }

          final response = await http.put(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(banco.toJson()),
          );

          if (kDebugMode) {
            print('Status code para PUT $endpoint: ${response.statusCode}');
            print('Resposta para PUT $endpoint: ${response.body}');
          }

          if (response.statusCode == 200 || response.statusCode == 204) {
            if (kDebugMode) {
              print('Sucesso com PUT para: $endpoint');
            }

            if (response.statusCode == 204 || response.body.isEmpty) {
              // Se não retornar dados, retorne o objeto original
              return banco;
            } else {
              try {
                return BancoModel.fromJson(json.decode(response.body));
              } catch (e) {
                if (kDebugMode) {
                  print('Erro ao converter resposta para BancoModel: $e');
                }
                // Retornar o objeto original se não conseguir converter
                return banco;
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Erro ao tentar PUT para $endpoint: $e');
          }
        }

        // Tentar com POST
        try {
          if (kDebugMode) {
            print('Tentando POST para: $endpoint');
          }

          final response = await http.post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'X-HTTP-Method-Override':
                  'PUT', // Alguns servidores suportam isso
            },
            body: json.encode(banco.toJson()),
          );

          if (kDebugMode) {
            print('Status code para POST $endpoint: ${response.statusCode}');
            print('Resposta para POST $endpoint: ${response.body}');
          }

          if (response.statusCode == 200 ||
              response.statusCode == 201 ||
              response.statusCode == 204) {
            if (kDebugMode) {
              print('Sucesso com POST para: $endpoint');
            }

            if (response.statusCode == 204 || response.body.isEmpty) {
              // Se não retornar dados, retorne o objeto original
              return banco;
            } else {
              try {
                return BancoModel.fromJson(json.decode(response.body));
              } catch (e) {
                if (kDebugMode) {
                  print('Erro ao converter resposta para BancoModel: $e');
                }
                // Retornar o objeto original se não conseguir converter
                return banco;
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Erro ao tentar POST para $endpoint: $e');
          }
        }
      }

      throw Exception(
          'Falha ao atualizar banco: nenhum método ou endpoint funcionou');
    } catch (e) {
      if (kDebugMode) {
        print('Erro geral na requisição de atualização: $e');
      }
      throw Exception('Erro ao atualizar banco: $e');
    }
  }

  Future<bool> deleteBanco(int bancoId, int usuarioId) async {
    // Verificar a URL base para garantir que está correta
    if (kDebugMode) {
      print('URL Base da API: $baseUrl');
      print('Fazendo requisição DELETE para: $baseUrl/bancos/$bancoId');
    }

    try {
      // Tentar com e sem o prefixo /api
      final urls = [
        '$baseUrl/bancos/$bancoId',
        '$baseUrl/api/bancos/$bancoId',
      ];

      for (var url in urls) {
        if (kDebugMode) {
          print('Tentando URL: $url');
        }

        try {
          final response = await http.delete(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (kDebugMode) {
            print('Status code para $url: ${response.statusCode}');
            print('Resposta para $url: ${response.body}');
          }

          if (response.statusCode == 200 || response.statusCode == 204) {
            if (kDebugMode) {
              print('Sucesso com URL: $url');
            }
            return true;
          }
        } catch (e) {
          if (kDebugMode) {
            print('Erro ao tentar $url: $e');
          }
        }
      }

      throw Exception('Falha ao excluir banco: nenhuma URL funcionou');
    } catch (e) {
      if (kDebugMode) {
        print('Erro geral na requisição: $e');
      }
      throw Exception('Erro ao excluir banco: $e');
    }
  }
}
