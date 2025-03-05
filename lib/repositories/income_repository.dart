import 'package:controle_gasto_pessoal/models/api_response.dart';
import 'package:controle_gasto_pessoal/repositories/base_repository.dart';
import 'package:controle_gasto_pessoal/services/api_service.dart';
import 'package:controle_gasto_pessoal/pages/income_page.dart';

class IncomeRepository extends BaseRepository<Income> {
  IncomeRepository(ApiService apiService) : super(apiService, 'incomes');

  @override
  Income fromJson(Map<String, dynamic> json) {
    return Income(
      isSalary: json['isSalary'] ?? false,
      company: json['company'],
      description: json['description'],
      amount: json['amount']?.toDouble() ?? 0.0,
      receiptDate: json['receiptDate'] != null
          ? DateTime.parse(json['receiptDate'])
          : DateTime.now(),
    );
  }

  @override
  Map<String, dynamic> toJson(Income income) {
    return {
      'isSalary': income.isSalary,
      'company': income.company,
      'description': income.description,
      'amount': income.amount,
      'receiptDate': income.receiptDate.toIso8601String(),
    };
  }

  // Métodos específicos para entradas
  Future<ApiResponse<List<Income>>> getByMonth(int month, int year) async {
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
}
