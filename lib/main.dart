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
import 'package:controle_gasto_pessoal/utils/api_provider.dart';
import 'package:controle_gasto_pessoal/utils/auth_provider.dart';
import 'package:controle_gasto_pessoal/config/environment.dart';
import 'package:flutter/foundation.dart';

void main() async {
  // Garantir que os widgets estejam inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // Exibir informações sobre o ambiente atual
  if (kDebugMode) {
    print('Ambiente: ${AppConfig.currentEnvironment}');
    print('URL da API: ${AppConfig.apiBaseUrl}');
  }

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AuthProvider(
      child: ApiProvider(
        child: MaterialApp(
          title: 'Controle Financeiro Pessoal',
          theme: AppTheme.darkTheme,
          initialRoute: '/login',
          routes: {
            '/login': (context) => LoginPage(),
            '/': (context) => HomePage(),
            '/bank_registration': (context) => BankRegistrationPage(),
            '/company_registration': (context) => CompanyRegistrationPage(),
            '/savings': (context) => SavingsPage(),
            '/categories': (context) => CategoryPage(),
            '/expenses': (context) => ExpensesPage(),
            '/income': (context) => IncomePage(),
          },
        ),
      ),
    );
  }
}
