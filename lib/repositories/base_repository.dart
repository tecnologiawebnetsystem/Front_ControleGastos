import 'package:controle_gasto_pessoal/services/api_service.dart';
import 'package:controle_gasto_pessoal/models/api_response.dart';

abstract class BaseRepository<T> {
  // Removido o underscore para tornar o campo acessível às subclasses
  final ApiService apiService;
  final String endpoint;

  BaseRepository(this.apiService, this.endpoint);

  // Método para converter JSON em objeto do tipo T
  T fromJson(Map<String, dynamic> json);

  // Método para converter objeto do tipo T em JSON
  Map<String, dynamic> toJson(T item);

  // Obter todos os itens
  Future<ApiResponse<List<T>>> getAll() async {
    try {
      final response = await apiService.get(endpoint);

      if (response is List) {
        final items = response.map((item) => fromJson(item)).toList();
        return ApiResponse.success(items);
      } else if (response is Map<String, dynamic> &&
          response.containsKey('data')) {
        final data = response['data'] as List;
        final items = data.map((item) => fromJson(item)).toList();
        return ApiResponse.success(items, message: response['message']);
      }

      return ApiResponse.error('Formato de resposta inválido');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Obter um item pelo ID
  Future<ApiResponse<T>> getById(String id) async {
    try {
      final response = await apiService.get('$endpoint/$id');

      if (response is Map<String, dynamic>) {
        if (response.containsKey('data')) {
          return ApiResponse.success(fromJson(response['data']),
              message: response['message']);
        }
        return ApiResponse.success(fromJson(response));
      }

      return ApiResponse.error('Formato de resposta inválido');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Criar um novo item
  Future<ApiResponse<T>> create(T item) async {
    try {
      final response = await apiService.post(endpoint, toJson(item));

      if (response is Map<String, dynamic>) {
        if (response.containsKey('data')) {
          return ApiResponse.success(fromJson(response['data']),
              message: response['message']);
        }
        return ApiResponse.success(fromJson(response));
      }

      return ApiResponse.error('Formato de resposta inválido');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Atualizar um item existente
  Future<ApiResponse<T>> update(String id, T item) async {
    try {
      final response = await apiService.put('$endpoint/$id', toJson(item));

      if (response is Map<String, dynamic>) {
        if (response.containsKey('data')) {
          return ApiResponse.success(fromJson(response['data']),
              message: response['message']);
        }
        return ApiResponse.success(fromJson(response));
      }

      return ApiResponse.error('Formato de resposta inválido');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  // Excluir um item
  Future<ApiResponse<bool>> delete(String id) async {
    try {
      final response = await apiService.delete('$endpoint/$id');

      if (response == null ||
          (response is Map<String, dynamic> && response['success'] == true)) {
        return ApiResponse.success(true, message: 'Item excluído com sucesso');
      }

      return ApiResponse.error('Não foi possível excluir o item');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
