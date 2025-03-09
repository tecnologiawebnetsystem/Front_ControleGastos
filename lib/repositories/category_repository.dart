import 'package:flutter/foundation.dart';
import 'package:controle_gasto_pessoal/models/expense_category.dart';
import 'package:controle_gasto_pessoal/services/api_service.dart';
import 'package:controle_gasto_pessoal/services/auth_service.dart';

class CategoryRepository {
  final ApiService apiService;
  final AuthService _authService = AuthService();
  final String endpoint = 'categorias';

  CategoryRepository(this.apiService) {
    // Garantir que o token de autenticação seja configurado
    _setupAuthToken();
  }

  // Configurar o token de autenticação no ApiService
  Future<void> _setupAuthToken() async {
    final token = _authService.getToken();
    if (token != null) {
      apiService.authToken = token;
      if (kDebugMode) {
        print('Token configurado no CategoryRepository: $token');
      }
    } else {
      if (kDebugMode) {
        print('Token não encontrado no AuthService');
      }
    }
  }

  // Método para converter JSON em objeto ExpenseCategory
  ExpenseCategory fromJson(Map<String, dynamic> json) {
    return ExpenseCategory.fromJson(json);
  }

  // Método para converter objeto ExpenseCategory em JSON
  Map<String, dynamic> toJson(ExpenseCategory item) {
    return item.toJson();
  }

  // Obter todas as categorias
  Future<Map<String, dynamic>> getAll() async {
    // Garantir que o token esteja configurado antes de fazer a requisição
    await _setupAuthToken();

    try {
      final response = await apiService.get(endpoint);

      if (response is List) {
        final items = response
            .map((item) => fromJson(item as Map<String, dynamic>))
            .toList();
        return {
          'success': true,
          'data': items,
        };
      } else if (response is Map<String, dynamic> &&
          response.containsKey('data')) {
        if (response['data'] is List) {
          final data = response['data'] as List;
          final items = data
              .map((item) => fromJson(item as Map<String, dynamic>))
              .toList();
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
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Obter categoria por ID
  Future<Map<String, dynamic>> getById(String id) async {
    await _setupAuthToken();

    try {
      final response = await apiService.get('$endpoint/$id');

      if (response is Map<String, dynamic>) {
        if (response.containsKey('data')) {
          return {
            'success': true,
            'data': fromJson(response['data']),
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
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Criar uma nova categoria
  Future<Map<String, dynamic>> create(ExpenseCategory item) async {
    await _setupAuthToken();

    try {
      // Converter para JSON, excluindo o ID e usando a convenção de nomenclatura Pascal Case
      final Map<String, dynamic> data = {
        'Nome': item.name, // "Nome" em vez de "nome"
        'Coeficiente':
            item.coefficient, // "Coeficiente" em vez de "coeficiente"
      };

      if (kDebugMode) {
        print('Criando categoria com dados: $data');
      }

      final response = await apiService.post(endpoint, data);

      if (response is Map<String, dynamic>) {
        if (response.containsKey('data')) {
          return {
            'success': true,
            'data': fromJson(response['data']),
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
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Atualizar uma categoria existente
  Future<Map<String, dynamic>> update(String id, ExpenseCategory item) async {
    await _setupAuthToken();

    try {
      // Validate the ID before sending the request
      if (id == 'null' || id.isEmpty) {
        return {
          'success': false,
          'message': 'ID inválido para atualização',
        };
      }

      // Ensure the ID is a valid integer
      int? numericId = int.tryParse(id);
      if (numericId == null) {
        return {
          'success': false,
          'message': 'ID deve ser um número válido',
        };
      }

      // Garantir que o ID esteja definido corretamente
      item.id = numericId;

      // Converter para JSON, incluindo o ID e usando a convenção de nomenclatura Pascal Case
      final Map<String, dynamic> data = {
        'Id': numericId, // "Id" em vez de "id"
        'Nome': item.name, // "Nome" em vez de "nome"
        'Coeficiente':
            item.coefficient, // "Coeficiente" em vez de "coeficiente"
      };

      if (kDebugMode) {
        print('Atualizando categoria com dados: $data');
      }

      final response = await apiService.put('$endpoint/$id', data);

      if (response is Map<String, dynamic>) {
        if (response.containsKey('data')) {
          return {
            'success': true,
            'data': fromJson(response['data']),
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
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }

  // Excluir uma categoria
  Future<Map<String, dynamic>> delete(String id) async {
    await _setupAuthToken();

    try {
      // Validate the ID before sending the request
      if (id == 'null' || id.isEmpty) {
        return {
          'success': false,
          'message': 'ID inválido para exclusão',
        };
      }

      // Ensure the ID is a valid integer
      int? numericId = int.tryParse(id);
      if (numericId == null) {
        return {
          'success': false,
          'message': 'ID deve ser um número válido',
        };
      }

      if (kDebugMode) {
        print('Excluindo categoria com ID: $id');
      }

      final response = await apiService.delete('$endpoint/$id');

      if (response == null ||
          (response is Map<String, dynamic> && response['success'] == true)) {
        return {
          'success': true,
          'message': 'Categoria excluída com sucesso',
        };
      }

      return {
        'success': false,
        'message': 'Não foi possível excluir a categoria',
      };
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}
