import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:controle_gasto_pessoal/services/auth_service.dart';

class AdminPage extends StatefulWidget {
  @override
  _AdminPageState createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool _isAdmin = false;
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  // Verificar se o usuário é administrador
  Future<void> _checkAdminStatus() async {
    try {
      final userData = await _authService.getUserData();
      if (userData != null) {
        setState(() {
          // Verificar diferentes possibilidades para o campo adm
          _isAdmin = userData['adm'] == true ||
              userData['adm'] == 1 ||
              userData['Adm'] == true ||
              userData['Adm'] == 1;
        });

        if (kDebugMode) {
          print('Status de administrador: $_isAdmin');
          print('Dados do usuário: $userData');
        }

        // Se não for admin, redirecionar para a página inicial
        if (!_isAdmin) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Acesso restrito a administradores'),
                backgroundColor: Colors.red,
              ),
            );
            Navigator.of(context).pushReplacementNamed('/');
          });
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao verificar status de administrador: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1F2937),
      appBar: AppBar(
        title: Text('Administração'),
        backgroundColor: Color(0xFF111827),
      ),
      body: _isAdmin
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: GridView.count(
                crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildAdminCard(
                    context,
                    'Categorias',
                    Icons.category,
                    '/categories',
                    'Gerenciar categorias de despesas e receitas',
                  ),
                  _buildAdminCard(
                    context,
                    'Tipos de Contratação',
                    Icons.work,
                    '/contract_types',
                    'Gerenciar tipos de contratação para empresas',
                  ),
                  _buildAdminCard(
                    context,
                    'Tipos de Operação',
                    Icons.settings,
                    '/operation_types',
                    'Gerenciar tipos de operação financeira',
                  ),
                  _buildAdminCard(
                    context,
                    'Status de Pagamento',
                    Icons.payment,
                    '/payment_status',
                    'Gerenciar status de pagamento para despesas',
                  ),
                ],
              ),
            )
          : Center(
              child: CircularProgressIndicator(),
            ),
    );
  }

  Widget _buildAdminCard(BuildContext context, String title, IconData icon,
      String route, String description) {
    return Card(
      color: Color(0xFF374151),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, route);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 48,
                color: Colors.blue,
              ),
              SizedBox(height: 16),
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                description,
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
