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
    if (kDebugMode) {
      print('Fazendo requisição GET para: $baseUrl/bancos');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/bancos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode) {
        print('Status code: ${response.statusCode}');
        print('Resposta: ${response.body}');
      }

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        // Filtra os bancos pelo ID do usuário, caso a API não faça isso automaticamente
        final bancos = data
            .map((json) => BancoModel.fromJson(json))
            .where((banco) => banco.usuarioId == usuarioId)
            .toList();
        return bancos;
      } else {
        if (kDebugMode) {
          print('Falha ao carregar bancos: ${response.statusCode}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro na requisição: $e');
      }
      // Retorne uma lista vazia em vez de lançar uma exceção
      return [];
    }
  }

  Future<BancoModel> createBanco(BancoModel banco) async {
    if (kDebugMode) {
      print('Fazendo requisição POST para: $baseUrl/bancos');
      print('Dados: ${json.encode(banco.toJson())}');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/bancos'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(banco.toJson()),
      );

      if (kDebugMode) {
        print('Status code: ${response.statusCode}');
        print('Resposta: ${response.body}');
      }

      if (response.statusCode == 201 || response.statusCode == 200) {
        return BancoModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Falha ao criar banco: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro na requisição: $e');
      }
      throw Exception('Erro ao criar banco: $e');
    }
  }

  Future<BancoModel> updateBanco(BancoModel banco) async {
    if (kDebugMode) {
      print('Fazendo requisição PUT para: $baseUrl/bancos/${banco.bancoId}');
      print('Dados: ${json.encode(banco.toJson())}');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/bancos/${banco.bancoId}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: json.encode(banco.toJson()),
      );

      if (kDebugMode) {
        print('Status code: ${response.statusCode}');
        print('Resposta: ${response.body}');
      }

      if (response.statusCode == 200) {
        return BancoModel.fromJson(json.decode(response.body));
      } else {
        throw Exception('Falha ao atualizar banco: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro na requisição: $e');
      }
      throw Exception('Erro ao atualizar banco: $e');
    }
  }

  Future<bool> deleteBanco(int bancoId, int usuarioId) async {
    if (kDebugMode) {
      print('Fazendo requisição DELETE para: $baseUrl/bancos/$bancoId');
    }

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/bancos/$bancoId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (kDebugMode) {
        print('Status code: ${response.statusCode}');
        print('Resposta: ${response.body}');
      }

      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception('Falha ao excluir banco: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro na requisição: $e');
      }
      throw Exception('Erro ao excluir banco: $e');
    }
  }
}
