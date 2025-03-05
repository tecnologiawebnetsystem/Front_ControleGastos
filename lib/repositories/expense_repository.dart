import 'package:controle_gasto_pessoal/models/api_response.dart';
import 'package:controle_gasto_pessoal/repositories/base_repository.dart';
import 'package:controle_gasto_pessoal/services/api_service.dart';
import 'package:controle_gasto_pessoal/pages/expenses_page.dart';

class ExpenseRepository extends BaseRepository<Expense> {
  ExpenseRepository(ApiService apiService) : super(apiService, 'expenses');

  @override
  Expense fromJson(Map<String, dynamic> json) {
    return Expense(
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      dueDate: json['dueDate'] != null
          ? DateTime.parse(json['dueDate'])
          : DateTime.now(),
      totalAmount: json['totalAmount']?.toDouble() ?? 0.0,
      installmentAmount: json['installmentAmount']?.toDouble() ?? 0.0,
      installmentNumber: json['installmentNumber'],
      totalInstallments: json['totalInstallments'],
      isPaid: json['isPaid'] ?? false,
      paymentDate: json['paymentDate'] != null
          ? DateTime.parse(json['paymentDate'])
          : null,
    );
  }

  @override
  Map<String, dynamic> toJson(Expense expense) {
    return {
      'category': expense.category,
      'description': expense.description,
      'dueDate': expense.dueDate.toIso8601String(),
      'totalAmount': expense.totalAmount,
      'installmentAmount': expense.installmentAmount,
      'installmentNumber': expense.installmentNumber,
      'totalInstallments': expense.totalInstallments,
      'isPaid': expense.isPaid,
      'paymentDate': expense.paymentDate?.toIso8601String(),
    };
  }

  // Métodos específicos para despesas
  Future<ApiResponse<List<Expense>>> getByMonth(int month, int year) async {
    try {
      final response = await apiService.get('$endpoint/month/$year/$month');

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

  Future<ApiResponse<double>> getTotalByMonth(int month, int year) async {
    try {
      final response = await apiService.get('$endpoint/total/$year/$month');

      if (response is Map<String, dynamic>) {
        if (response.containsKey('data')) {
          return ApiResponse.success(response['data'].toDouble(),
              message: response['message']);
        }
        return ApiResponse.success(response['total']?.toDouble() ?? 0.0);
      }

      return ApiResponse.error('Formato de resposta inválido');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }

  Future<ApiResponse<bool>> markAsPaid(String id) async {
    try {
      final response = await apiService.put('$endpoint/$id/pay',
          {'paymentDate': DateTime.now().toIso8601String()});

      if (response is Map<String, dynamic> && response['success'] == true) {
        return ApiResponse.success(true, message: response['message']);
      }

      return ApiResponse.error('Não foi possível marcar como pago');
    } catch (e) {
      return ApiResponse.error(e.toString());
    }
  }
}
