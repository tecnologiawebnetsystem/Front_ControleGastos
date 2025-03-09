import 'package:flutter/foundation.dart';
import 'package:controle_gasto_pessoal/models/payment_status.dart';
import 'package:controle_gasto_pessoal/services/api_service.dart';
import 'package:controle_gasto_pessoal/services/auth_service.dart';
import 'package:controle_gasto_pessoal/config/environment.dart';

class PaymentStatusRepository {
  final ApiService apiService;
  final AuthService _authService = AuthService();

  // Specific endpoint for payment status
  final String endpoint = 'status-pagamento';

  PaymentStatusRepository(this.apiService) {
    _setupAuthToken();
  }

  // Configurar o token de autenticação no ApiService
  Future<void> _setupAuthToken() async {
    final token = _authService.getToken();
    if (token != null) {
      apiService.authToken = token;
      if (kDebugMode) {
        print('Token configurado no PaymentStatusRepository: $token');
      }
    } else {
      if (kDebugMode) {
        print('Token não encontrado no AuthService');
      }
    }
  }

  // Método para converter JSON em objeto PaymentStatus
  PaymentStatus fromJson(Map<String, dynamic> json, {int? mockId}) {
    if (kDebugMode) {
      print('PaymentStatusRepository.fromJson: $json');
    }
    return PaymentStatus.fromJson(json, mockId: mockId);
  }

  // Método para converter objeto PaymentStatus em JSON
  Map<String, dynamic> toJson(PaymentStatus item) {
    return item.toJson();
  }

  // Obter todos os status de pagamento
  Future<Map<String, dynamic>> getAll() async {
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
        };
      } else if (response is Map<String, dynamic> &&
          response.containsKey('data')) {
        if (response['data'] is List) {
          final data = response['data'] as List;
          final items = data.map((item) {
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

      // If we reach here, the response format is unexpected
      return {
        'success': false,
        'message': 'Formato de resposta inválido',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao obter status de pagamento: $e');
      }
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Obter status de pagamento por ID
  Future<Map<String, dynamic>> getById(String id) async {
    await _setupAuthToken();

    try {
      final response = await apiService.get('$endpoint/$id');

      if (response is Map<String, dynamic>) {
        if (response.containsKey('data')) {
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
        print('Erro ao obter status de pagamento por ID: $e');
      }
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Criar um novo status de pagamento
  Future<Map<String, dynamic>> create(PaymentStatus item) async {
    await _setupAuthToken();

    try {
      final data = {
        'Descricao': item.description,
      };

      if (kDebugMode) {
        print('Criando status de pagamento com dados: $data');
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
          } else if (dataObj.containsKey('statusPagamentoId')) {
            newId = dataObj['statusPagamentoId'] is int
                ? dataObj['statusPagamentoId']
                : int.tryParse(dataObj['statusPagamentoId'].toString());
          } else if (dataObj.containsKey('StatusPagamentoId')) {
            newId = dataObj['StatusPagamentoId'] is int
                ? dataObj['StatusPagamentoId']
                : int.tryParse(dataObj['StatusPagamentoId'].toString());
          }
        }
      }

      if (kDebugMode) {
        print('ID extraído da resposta: $newId');
      }

      // Create a new PaymentStatus with the extracted ID
      PaymentStatus createdItem = PaymentStatus(
        id: newId ?? item.id,
        description: item.description,
      );

      if (kDebugMode) {
        print('Status de pagamento criado: $createdItem');
      }

      return {
        'success': true,
        'data': createdItem,
        'message': 'Status de pagamento criado com sucesso',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao criar status de pagamento: $e');
      }
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Atualizar um status de pagamento existente
  Future<Map<String, dynamic>> update(String id, PaymentStatus item) async {
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
      };

      if (kDebugMode) {
        print('Atualizando status de pagamento com ID: $numericId');
        print('Dados enviados: $data');
      }

      // Try different endpoint patterns
      Map<String, dynamic>? response;
      Exception? lastException;

      // List of possible endpoint patterns to try
      final endpointPatterns = [
        '$endpoint/$numericId', // Standard REST pattern
        '$endpoint/update/$numericId', // Common alternative
        '$endpoint/editar/$numericId', // Portuguese alternative
        '$endpoint', // Some APIs expect ID in the body only
        'status-pagamento/$numericId', // Plural form
        'status-pagamento/update/$numericId', // Plural with update
        'status-pagamento/editar/$numericId', // Plural with Portuguese
        'status-pagamento', // Plural with ID in body
      ];

      for (var pattern in endpointPatterns) {
        try {
          if (kDebugMode) {
            print('Tentando endpoint: $pattern');
          }

          response = await apiService.put(pattern, data);

          if (kDebugMode) {
            print('Resposta da API (update): $response');
          }

          // If we got here without an exception, break the loop
          break;
        } catch (e) {
          lastException = e as Exception;
          if (kDebugMode) {
            print('Erro ao tentar endpoint $pattern: $e');
          }
          // Continue to the next pattern
        }
      }

      // If all patterns failed, try a POST request with _method=PUT
      if (response == null) {
        try {
          if (kDebugMode) {
            print('Tentando POST com _method=PUT');
          }

          final postData = Map<String, dynamic>.from(data);
          postData['_method'] = 'PUT'; // Some frameworks use this pattern

          response = await apiService.post('$endpoint/$numericId', postData);

          if (kDebugMode) {
            print('Resposta da API (POST com _method=PUT): $response');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Erro ao tentar POST com _method=PUT: $e');
          }
          // If this also fails, we'll use the last exception from the loop
        }
      }

      // If we still don't have a response, throw the last exception
      if (response == null) {
        throw lastException ??
            Exception('Falha ao atualizar status de pagamento');
      }

      // Process the response
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
                'Status de pagamento atualizado com sucesso',
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
          'message': 'Status de pagamento atualizado com sucesso',
        };
      }

      // Se chegou até aqui, considerar como sucesso
      return {
        'success': true,
        'data': item,
        'message': 'Status de pagamento atualizado com sucesso',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao atualizar status de pagamento: $e');
      }
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Excluir um status de pagamento
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
        print('Excluindo status de pagamento com ID: $numericId');
      }

      // Try different endpoint patterns
      Map<String, dynamic>? response;
      Exception? lastException;

      // List of possible endpoint patterns to try
      final endpointPatterns = [
        '$endpoint/$numericId', // Standard REST pattern
        '$endpoint/delete/$numericId', // Common alternative
        '$endpoint/remover/$numericId', // Portuguese alternative
        '$endpoint/excluir/$numericId', // Another Portuguese alternative
        'status-pagamento/$numericId', // Plural form
        'status-pagamento/delete/$numericId', // Plural with delete
        'status-pagamento/remover/$numericId', // Plural with Portuguese
        'status-pagamento/excluir/$numericId', // Plural with another Portuguese
      ];

      for (var pattern in endpointPatterns) {
        try {
          if (kDebugMode) {
            print('Tentando endpoint: $pattern');
          }

          response = await apiService.delete(pattern);

          if (kDebugMode) {
            print('Resposta da API (delete): $response');
          }

          // If we got here without an exception, break the loop
          break;
        } catch (e) {
          lastException = e as Exception;
          if (kDebugMode) {
            print('Erro ao tentar endpoint $pattern: $e');
          }
          // Continue to the next pattern
        }
      }

      // If all patterns failed, try a POST request with _method=DELETE
      if (response == null) {
        try {
          if (kDebugMode) {
            print('Tentando POST com _method=DELETE');
          }

          final postData = {
            'Id': numericId,
            '_method': 'DELETE', // Some frameworks use this pattern
          };

          response = await apiService.post('$endpoint/$numericId', postData);

          if (kDebugMode) {
            print('Resposta da API (POST com _method=DELETE): $response');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Erro ao tentar POST com _method=DELETE: $e');
          }
          // If this also fails, we'll use the last exception from the loop
        }
      }

      // If we still don't have a response, throw the last exception
      if (response == null) {
        throw lastException ??
            Exception('Falha ao excluir status de pagamento');
      }

      // Always return success if we didn't get an exception
      return {
        'success': true,
        'message': 'Status de pagamento excluído com sucesso',
      };
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao excluir status de pagamento: $e');
      }
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
