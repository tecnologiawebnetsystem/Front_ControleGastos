import 'package:flutter/foundation.dart';
import 'package:controle_gasto_pessoal/models/operation_type.dart';
import 'package:controle_gasto_pessoal/services/api_service.dart';
import 'package:controle_gasto_pessoal/services/auth_service.dart';

class OperationTypeRepository {
  final ApiService apiService;
  final AuthService _authService = AuthService();

  // Endpoint da API
  final String endpoint = 'tipos-operacao';

  OperationTypeRepository(this.apiService) {
    // Garantir que o token de autenticação seja configurado
    _setupAuthToken();
  }

  // Configurar o token de autenticação no ApiService
  Future<void> _setupAuthToken() async {
    final token = _authService.getToken();
    if (token != null) {
      apiService.authToken = token;
      if (kDebugMode) {
        print('Token configurado no OperationTypeRepository: $token');
      }
    } else {
      if (kDebugMode) {
        print('Token não encontrado no AuthService');
      }
    }
  }

  // Método para converter JSON em objeto OperationType
  OperationType fromJson(Map<String, dynamic> json, {int? mockId}) {
    if (kDebugMode) {
      print('OperationTypeRepository.fromJson: $json');
    }
    return OperationType.fromJson(json, mockId: mockId);
  }

  // Método para converter objeto OperationType em JSON
  Map<String, dynamic> toJson(OperationType item) {
    return item.toJson();
  }

  // Obter todos os tipos de operação
  Future<Map<String, dynamic>> getAll() async {
    // Garantir que o token esteja configurado antes de fazer a requisição
    await _setupAuthToken();

    try {
      if (kDebugMode) {
        print('Fazendo requisição GET para: $endpoint');
      }

      final response = await apiService.get(endpoint);

      if (kDebugMode) {
        print('Resposta da API (getAll): $response');
        print('Tipo da resposta: ${response.runtimeType}');
      }

      if (response is List) {
        if (kDebugMode) {
          print('Resposta é uma lista com ${response.length} itens');
        }

        final items = response.map((item) {
          if (kDebugMode) {
            print('Processando item: $item');
          }

          // Garantir que o item seja um Map<String, dynamic>
          Map<String, dynamic> itemMap;
          if (item is Map<String, dynamic>) {
            itemMap = item;
          } else {
            itemMap = Map<String, dynamic>.from(item as Map);
          }

          return fromJson(itemMap);
        }).toList();

        if (kDebugMode) {
          print('Itens processados: ${items.length}');
          for (var item in items) {
            print('Item processado: $item');
          }
        }

        return {
          'success': true,
          'data': items,
        };
      } else if (response is Map<String, dynamic> &&
          response.containsKey('data')) {
        if (response['data'] is List) {
          final data = response['data'] as List;
          if (kDebugMode) {
            print(
                'Resposta contém uma lista de dados com ${data.length} itens');
          }

          final items = data.map((item) {
            // Garantir que o item seja um Map<String, dynamic>
            Map<String, dynamic> itemMap;
            if (item is Map<String, dynamic>) {
              itemMap = item;
            } else {
              itemMap = Map<String, dynamic>.from(item as Map);
            }

            return fromJson(itemMap);
          }).toList();

          return {
            'success': true,
            'data': items,
            'message': response['message'],
          };
        }
      }

      return {
        'success': false,
        'message': 'Formato de resposta inválido',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao obter tipos de operação: $e');
      }
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Obter tipo de operação por ID
  Future<Map<String, dynamic>> getById(String id) async {
    await _setupAuthToken();

    try {
      final response = await apiService.get('$endpoint/$id');

      if (response is Map<String, dynamic>) {
        if (response.containsKey('data')) {
          // Garantir que data seja um Map<String, dynamic>
          Map<String, dynamic> dataMap;
          if (response['data'] is Map<String, dynamic>) {
            dataMap = response['data'];
          } else {
            dataMap = Map<String, dynamic>.from(response['data'] as Map);
          }

          return {
            'success': true,
            'data': fromJson(dataMap),
            'message': response['message'],
          };
        }
        return {
          'success': true,
          'data': fromJson(response),
        };
      }

      return {
        'success': false,
        'message': 'Formato de resposta inválido',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao obter tipo de operação por ID: $e');
      }
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Criar um novo tipo de operação
  Future<Map<String, dynamic>> create(OperationType item) async {
    await _setupAuthToken();

    try {
      // Converter para JSON, excluindo o ID e usando a convenção de nomenclatura Pascal Case
      final Map<String, dynamic> data = {
        'Descricao': item.description,
        'Coeficiente': item.coefficient,
      };

      if (kDebugMode) {
        print('Criando tipo de operação com dados: $data');
      }

      final response = await apiService.post(endpoint, data);

      if (kDebugMode) {
        print('Resposta da API (create): $response');
      }

      // Extract the ID from the response
      int? newId;
      if (response is Map<String, dynamic>) {
        // Try to extract ID directly from response
        if (response.containsKey('id')) {
          newId = response['id'] is int
              ? response['id']
              : int.tryParse(response['id'].toString());
        } else if (response.containsKey('Id')) {
          newId = response['Id'] is int
              ? response['Id']
              : int.tryParse(response['Id'].toString());
        }

        // Try to extract from data object if present
        if (newId == null &&
            response.containsKey('data') &&
            response['data'] is Map<String, dynamic>) {
          var dataObj = response['data'] as Map<String, dynamic>;
          if (dataObj.containsKey('id')) {
            newId = dataObj['id'] is int
                ? dataObj['id']
                : int.tryParse(dataObj['id'].toString());
          } else if (dataObj.containsKey('Id')) {
            newId = dataObj['Id'] is int
                ? dataObj['Id']
                : int.tryParse(dataObj['Id'].toString());
          } else if (dataObj.containsKey('tipoOperacaoId')) {
            newId = dataObj['tipoOperacaoId'] is int
                ? dataObj['tipoOperacaoId']
                : int.tryParse(dataObj['tipoOperacaoId'].toString());
          } else if (dataObj.containsKey('TipoOperacaoId')) {
            newId = dataObj['TipoOperacaoId'] is int
                ? dataObj['TipoOperacaoId']
                : int.tryParse(dataObj['TipoOperacaoId'].toString());
          }
        }
      }

      if (kDebugMode) {
        print('ID extraído da resposta: $newId');
      }

      // Create a new OperationType with the extracted ID
      OperationType createdItem = OperationType(
        id: newId ?? item.id,
        description: item.description,
        coefficient: item.coefficient,
      );

      if (kDebugMode) {
        print('Tipo de operação criado: $createdItem');
      }

      return {
        'success': true,
        'data': createdItem,
        'message': 'Tipo de operação criado com sucesso',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao criar tipo de operação: $e');
      }
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Atualizar um tipo de operação existente
  Future<Map<String, dynamic>> update(String id, OperationType item) async {
    await _setupAuthToken();

    try {
      // Validate the ID before sending the request
      if (id == 'null' || id.isEmpty) {
        if (kDebugMode) {
          print('ID inválido para atualização: $id');
        }
        return {
          'success': false,
          'message': 'ID inválido para atualização',
        };
      }

      // Ensure the ID is a valid integer
      int? numericId = int.tryParse(id);
      if (numericId == null) {
        if (kDebugMode) {
          print('ID não é um número válido: $id');
        }
        return {
          'success': false,
          'message': 'ID deve ser um número válido',
        };
      }

      // Garantir que o ID esteja definido corretamente no objeto
      item.id = numericId;

      // Converter para JSON, incluindo o ID e usando a convenção de nomenclatura Pascal Case
      final Map<String, dynamic> data = {
        'Id': numericId,
        'Descricao': item.description,
        'Coeficiente': item.coefficient,
      };

      if (kDebugMode) {
        print('Atualizando tipo de operação com ID: $numericId');
        print('Dados enviados: $data');
      }

      final response = await apiService.put('$endpoint/$numericId', data);

      if (kDebugMode) {
        print('Resposta da API (update): $response');
      }

      // Se a resposta for nula ou vazia, considerar como sucesso
      if (response == null ||
          (response is Map<String, dynamic> && response.isEmpty)) {
        return {
          'success': true,
          'data': item,
          'message': 'Tipo de operação atualizado com sucesso',
        };
      }

      if (response is Map<String, dynamic>) {
        if (response.containsKey('data')) {
          // Garantir que data seja um Map<String, dynamic>
          Map<String, dynamic> dataMap;
          if (response['data'] is Map<String, dynamic>) {
            dataMap = response['data'];
          } else {
            dataMap = Map<String, dynamic>.from(response['data'] as Map);
          }

          // Manter o ID original no objeto retornado
          return {
            'success': true,
            'data': fromJson(dataMap),
            'message': response['message'] ??
                'Tipo de operação atualizado com sucesso',
          };
        }

        // Se a resposta contiver uma mensagem de erro, retornar falha
        if (response.containsKey('message') && response['success'] == false) {
          return {
            'success': false,
            'message': response['message'],
          };
        }

        // Caso contrário, considerar como sucesso
        return {
          'success': true,
          'data': item,
          'message': 'Tipo de operação atualizado com sucesso',
        };
      }

      // Se chegou até aqui, considerar como sucesso
      return {
        'success': true,
        'data': item,
        'message': 'Tipo de operação atualizado com sucesso',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao atualizar tipo de operação: $e');
      }
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Excluir um tipo de operação
  Future<Map<String, dynamic>> delete(String id) async {
    await _setupAuthToken();

    try {
      // Validate the ID before sending the request
      if (id == 'null' || id.isEmpty) {
        if (kDebugMode) {
          print('ID inválido para exclusão: $id');
        }
        return {
          'success': false,
          'message': 'ID inválido para exclusão',
        };
      }

      // Ensure the ID is a valid integer
      int? numericId = int.tryParse(id);
      if (numericId == null) {
        if (kDebugMode) {
          print('ID não é um número válido para exclusão: $id');
        }
        return {
          'success': false,
          'message': 'ID deve ser um número válido',
        };
      }

      if (kDebugMode) {
        print('Excluindo tipo de operação com ID: $numericId');
      }

      try {
        // Use the numeric ID in the endpoint
        final response = await apiService.delete('$endpoint/$numericId');

        if (kDebugMode) {
          print('Resposta da exclusão: $response');
        }

        // Always return success if we didn't get an error
        return {
          'success': true,
          'message': 'Tipo de operação excluído com sucesso',
        };
      } catch (e) {
        if (kDebugMode) {
          print('Erro ao excluir tipo de operação: $e');
        }

        // Return a more user-friendly error message
        return {
          'success': false,
          'message':
              'Não foi possível excluir o tipo de operação. Verifique se ele existe no servidor.',
        };
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao excluir tipo de operação: $e');
      }
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
