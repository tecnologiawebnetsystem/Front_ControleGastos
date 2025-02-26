import 'package:flutter/material.dart';
import 'package:controle_gasto_pessoal/pages/home_page.dart';
import 'package:controle_gasto_pessoal/theme/app_theme.dart';
import 'package:controle_gasto_pessoal/pages/bank_registration_page.dart';
import 'package:controle_gasto_pessoal/pages/company_registration_page.dart';
import 'package:controle_gasto_pessoal/pages/savings_page.dart';
import 'package:controle_gasto_pessoal/pages/category_page.dart';
import 'package:controle_gasto_pessoal/pages/expenses_page.dart';
import 'package:controle_gasto_pessoal/pages/income_page.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Controle Financeiro Pessoal',
      theme: AppTheme.darkTheme,
      home: HomePage(),
      routes: {
        '/bank_registration': (context) => BankRegistrationPage(),
        '/company_registration': (context) => CompanyRegistrationPage(),
        '/savings': (context) => SavingsPage(),
        '/categories': (context) => CategoryPage(),
        '/expenses': (context) => ExpensesPage(),
        '/income': (context) => IncomePage(),
      },
    );
  }
}
