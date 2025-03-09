import 'package:flutter/material.dart';
import 'package:controle_gasto_pessoal/pages/home_page.dart';
import 'package:controle_gasto_pessoal/theme/app_theme.dart';
import 'package:controle_gasto_pessoal/pages/bank_registration_page.dart';
import 'package:controle_gasto_pessoal/pages/company_registration_page.dart';
import 'package:controle_gasto_pessoal/pages/savings_page.dart';
import 'package:controle_gasto_pessoal/pages/category_page.dart';
import 'package:controle_gasto_pessoal/pages/expenses_page.dart';
import 'package:controle_gasto_pessoal/pages/income_page.dart';
import 'package:controle_gasto_pessoal/pages/login_page.dart';
import 'package:controle_gasto_pessoal/pages/contract_type_page.dart';
import 'package:controle_gasto_pessoal/pages/operation_type_page.dart';
import 'package:controle_gasto_pessoal/pages/payment_status_page.dart';
import 'package:controle_gasto_pessoal/pages/admin_page.dart';
import 'package:controle_gasto_pessoal/config/environment.dart';
import 'package:flutter/foundation.dart';
import 'package:controle_gasto_pessoal/services/auth_service.dart';

void main() async {
  // Garantir que os widgets estejam inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Exibir informações sobre o ambiente atual
  if (kDebugMode) {
    print('Ambiente: ${AppConfig.currentEnvironment}');
    print('URL da API: ${AppConfig.apiBaseUrl}');
  }

  // Criar uma instância única do AuthService
  final authService = AuthService();

  // Verificar se o usuário já está autenticado
  final isAuthenticated = authService.isAuthenticated();
  if (kDebugMode) {
    print('Usuário autenticado: $isAuthenticated');
    print('Dados do usuário no início: ${authService.getUserData()}');
  }

  runApp(MyApp(
    initialRoute: isAuthenticated ? '/' : '/login',
  ));
}

class MyApp extends StatelessWidget {
  final String initialRoute;

  const MyApp({
    Key? key,
    required this.initialRoute,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle Financeiro Pessoal',
      theme: AppTheme.darkTheme,
      initialRoute: initialRoute,
      routes: {
        '/login': (context) => LoginPage(),
        '/': (context) => HomePage(),
        '/bank_registration': (context) => BankRegistrationPage(),
        '/company_registration': (context) => CompanyRegistrationPage(),
        '/savings': (context) => SavingsPage(),
        '/categories': (context) => CategoryPage(),
        '/expenses': (context) => ExpensesPage(),
        '/income': (context) => IncomePage(),
        '/contract_types': (context) => ContractTypePage(),
        '/operation_types': (context) => OperationTypePage(),
        '/payment_status': (context) => PaymentStatusPage(),
        '/admin': (context) => AdminPage(),
      },
    );
  }
}
