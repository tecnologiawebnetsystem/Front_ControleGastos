import 'package:flutter/material.dart';
import 'package:hello_world/pages/home_page.dart';
import 'package:hello_world/theme/app_theme.dart';
import 'package:hello_world/pages/bank_registration_page.dart';
import 'package:hello_world/pages/company_registration_page.dart';
import 'package:hello_world/pages/savings_page.dart';
import 'package:hello_world/pages/category_page.dart';

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
      },
    );
  }
}
