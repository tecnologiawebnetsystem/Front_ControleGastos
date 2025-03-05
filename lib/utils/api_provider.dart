import 'package:flutter/material.dart';
import 'package:controle_gasto_pessoal/services/api_service.dart';
import 'package:controle_gasto_pessoal/repositories/expense_repository.dart';
import 'package:controle_gasto_pessoal/repositories/income_repository.dart';

class ApiProvider extends InheritedWidget {
  final ApiService apiService;
  final ExpenseRepository expenseRepository;
  final IncomeRepository incomeRepository;
  
  ApiProvider({
    Key? key,
    required Widget child,
  }) : 
    apiService = ApiService(),
    expenseRepository = ExpenseRepository(ApiService()),
    incomeRepository = IncomeRepository(ApiService()),
    super(key: key, child: child);
  
  static ApiProvider of(BuildContext context) {
    final ApiProvider? result = context.dependOnInheritedWidgetOfExactType<ApiProvider>();
    assert(result != null, 'Nenhum ApiProvider encontrado no contexto');
    return result!;
  }
  
  @override
  bool updateShouldNotify(ApiProvider oldWidget) {
    return false;
  }
}

