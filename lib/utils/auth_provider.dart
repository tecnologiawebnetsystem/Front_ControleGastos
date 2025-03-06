import 'package:flutter/material.dart';
import 'package:controle_gasto_pessoal/services/auth_service.dart';

class AuthProvider extends InheritedWidget {
  final AuthService authService;

  AuthProvider({
    Key? key,
    required Widget child,
  }) : 
    authService = AuthService(),
    super(key: key, child: child);

  static AuthProvider of(BuildContext context) {
    final AuthProvider? result = context.dependOnInheritedWidgetOfExactType<AuthProvider>();
    assert(result != null, 'Nenhum AuthProvider encontrado no contexto');
    return result!;
  }

  @override
  bool updateShouldNotify(AuthProvider oldWidget) {
    return false;
  }
}

