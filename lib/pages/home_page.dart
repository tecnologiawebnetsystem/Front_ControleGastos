import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:controle_gasto_pessoal/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:controle_gasto_pessoal/components/finance_chat_box.dart';
import 'dart:math' show sin;

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
  String userName = 'Usuário';

  // Controle para o menu de administração expandido/recolhido
  bool _isAdminMenuExpanded = false;

  // Instância do AuthService (singleton)
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      // Tentar buscar dados atualizados do usuário do servidor
      await _authService.fetchUserData();

      // Obter os dados do usuário
      final userData = await _authService.getUserData();

      // Adicionar log para depuração
      if (kDebugMode) {
        print('Dados do usuário na HomePage: $userData');
      }

      // Verificar diferentes possibilidades para o nome do usuário
      String name = 'Usuário';
      if (userData != null) {
        if (userData.containsKey('nome')) {
          name = userData['nome'] ?? 'Usuário';
        } else if (userData.containsKey('name')) {
          name = userData['name'] ?? 'Usuário';
        } else if (userData.containsKey('Nome')) {
          name = userData['Nome'] ?? 'Usuário';
        }

        if (kDebugMode) {
          print('Nome do usuário encontrado: $name');
        }

        setState(() {
          userName = name;
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar dados do usuário: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1F2937),
      body: Stack(
        children: [
          Row(
            children: [
              // Menu fixo à esquerda
              if (MediaQuery.of(context).size.width >
                  600) // Só mostra o menu lateral em telas maiores
                Container(
                  width: 200,
                  color: Color(0xFF111827),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                      _buildMenuItem(context, 'Bancos', Icons.account_balance,
                          '/bank_registration'),
                      _buildMenuItem(context, 'Empresas', Icons.business,
                          '/company_registration'),
                      _buildMenuItem(
                          context, 'Despesas', Icons.money_off, '/expenses'),
                      _buildMenuItem(
                          context, 'Entradas', Icons.attach_money, '/income'),
                      _buildMenuItem(
                          context, 'Poupança', Icons.savings, '/savings'),

                      // Menu de Administração com submenu
                      ExpansionTile(
                        title: Text('Admin',
                            style: TextStyle(
                                color: Colors.white)), // Encurta o texto
                        leading: Icon(Icons.admin_panel_settings,
                            color: Colors.white),
                        collapsedIconColor: Colors.white,
                        iconColor: Colors.white,
                        backgroundColor: Color(0xFF111827),
                        collapsedBackgroundColor: Color(0xFF111827),
                        tilePadding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 0), // Reduz o padding
                        childrenPadding:
                            EdgeInsets.all(0), // Remove padding dos filhos
                        children: [
                          _buildSubmenuItem(context, 'Categorias',
                              Icons.category, '/categories'),
                          _buildSubmenuItem(context, 'Tipos Contratação',
                              Icons.work, '/contract_types'), // Encurta o texto
                          _buildSubmenuItem(
                              context,
                              'Tipos Operação',
                              Icons.settings,
                              '/operation_types'), // Encurta o texto
                          _buildSubmenuItem(
                              context,
                              'Status Pagamento',
                              Icons.payment,
                              '/payment_status'), // Encurta o texto
                        ],
                      ),
                    ],
                  ),
                ),
              // Conteúdo principal
              Expanded(
                child: Column(
                  children: [
                    // Barra superior com nome do usuário, ícone de logout e notificação
                    Container(
                      height: 60,
                      color: Color(0xFF111827),
                      child: Row(
                        children: [
                          if (MediaQuery.of(context).size.width <= 600)
                            IconButton(
                              icon: Icon(Icons.menu, color: Colors.white),
                              onPressed: () {
                                // Abre o drawer com o menu
                                Scaffold.of(context).openDrawer();
                              },
                            ),
                          Spacer(),
                          // Nome do usuário
                          Text(
                            'Olá, $userName',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(width: 16),
                          // Ícone de notificação
                          Icon(Icons.notifications, color: Colors.white),
                          SizedBox(width: 16),
                          // Ícone de logout
                          IconButton(
                            icon: Icon(Icons.exit_to_app, color: Colors.white),
                            tooltip: 'Sair',
                            onPressed: () {
                              // Mostrar diálogo de confirmação
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  backgroundColor: Color(0xFF374151),
                                  title: Text('Sair',
                                      style: TextStyle(color: Colors.white)),
                                  content: Text(
                                    'Tem certeza que deseja sair?',
                                    style: TextStyle(color: Colors.white70),
                                  ),
                                  actions: [
                                    TextButton(
                                      child: Text('Cancelar'),
                                      onPressed: () =>
                                          Navigator.of(context).pop(),
                                    ),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                      ),
                                      child: Text('Sair'),
                                      onPressed: () async {
                                        // Fazer logout
                                        await _authService.logout();

                                        // Navegar para a tela de login
                                        Navigator.of(context)
                                            .pushNamedAndRemoveUntil(
                                          '/login',
                                          (route) => false,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                          SizedBox(width: 16),
                        ],
                      ),
                    ),
                    // Conteúdo rolável
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Molduras
                            LayoutBuilder(
                              builder: (context, constraints) {
                                // Calcula o número de colunas com base na largura da tela
                                int crossAxisCount =
                                    MediaQuery.of(context).size.width > 600
                                        ? 3
                                        : 2;
                                double cardWidth = (constraints.maxWidth -
                                        (16 * (crossAxisCount - 1))) /
                                    crossAxisCount;
                                // Aumenta o tamanho em 5% (multiplica por 0.35 em vez de 0.3)
                                double finalCardWidth = cardWidth * 0.35;
                                double finalCardHeight = finalCardWidth;

                                return Wrap(
                                  spacing: 16,
                                  runSpacing: 16,
                                  children: [
                                    _buildInfoCard(
                                        'Poupança',
                                        5000,
                                        Colors.blue,
                                        finalCardWidth,
                                        finalCardHeight),
                                    _buildInfoCard(
                                        'Saldo',
                                        5000,
                                        Colors.greenAccent,
                                        finalCardWidth,
                                        finalCardHeight),
                                    _buildInfoCard('Despesas', 3000, Colors.red,
                                        finalCardWidth, finalCardHeight),
                                    _buildInfoCard(
                                        'Salário',
                                        7000,
                                        Colors.green,
                                        finalCardWidth,
                                        finalCardHeight),
                                    _buildInfoCard('Crédito', 1000, Colors.teal,
                                        finalCardWidth, finalCardHeight),
                                    _buildInfoCard('Empresas', 5, Colors.purple,
                                        finalCardWidth, finalCardHeight),
                                  ],
                                );
                              },
                            ),
                            SizedBox(height: 24),
                            Text(
                              'Movimentação do Mês - Março/2025',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            SizedBox(height: 16),
                            _buildExpensesGrid(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Adicionar o chatbox no canto inferior direito
          FinanceChatBox(),
        ],
      ),
      // Drawer para menu em dispositivos móveis
      drawer: MediaQuery.of(context).size.width <= 600
          ? Drawer(
              child: Container(
                color: Color(0xFF111827),
                child: ListView(
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(color: Color(0xFF1F2937)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 48,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Olá, $userName',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildMenuItem(context, 'Bancos', Icons.account_balance,
                        '/bank_registration'),
                    _buildMenuItem(context, 'Empresas', Icons.business,
                        '/company_registration'),
                    _buildMenuItem(
                        context, 'Despesas', Icons.money_off, '/expenses'),
                    _buildMenuItem(
                        context, 'Entradas', Icons.attach_money, '/income'),
                    _buildMenuItem(
                        context, 'Poupança', Icons.savings, '/savings'),

                    // Menu de Administração com submenu para dispositivos móveis
                    ExpansionTile(
                      title: Text('Administração',
                          style: TextStyle(color: Colors.white)),
                      leading:
                          Icon(Icons.admin_panel_settings, color: Colors.white),
                      collapsedIconColor: Colors.white,
                      iconColor: Colors.white,
                      backgroundColor: Color(0xFF111827),
                      collapsedBackgroundColor: Color(0xFF111827),
                      tilePadding: EdgeInsets.symmetric(
                          horizontal: 16, vertical: 0), // Reduz o padding
                      childrenPadding:
                          EdgeInsets.all(0), // Remove padding dos filhos
                      children: [
                        _buildSubmenuItem(context, 'Categorias', Icons.category,
                            '/categories'),
                        _buildSubmenuItem(context, 'Tipos Contratação',
                            Icons.work, '/contract_types'), // Encurta o texto
                        _buildSubmenuItem(
                            context,
                            'Tipos Operação',
                            Icons.settings,
                            '/operation_types'), // Encurta o texto
                        _buildSubmenuItem(
                            context,
                            'Status Pagamento',
                            Icons.payment,
                            '/payment_status'), // Encurta o texto
                      ],
                    ),

                    Divider(color: Colors.white24),
                    ListTile(
                      leading: Icon(Icons.exit_to_app, color: Colors.white),
                      title:
                          Text('Sair', style: TextStyle(color: Colors.white)),
                      onTap: () {
                        // Fechar o drawer
                        Navigator.of(context).pop();

                        // Mostrar diálogo de confirmação
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Color(0xFF374151),
                            title: Text('Sair',
                                style: TextStyle(color: Colors.white)),
                            content: Text(
                              'Tem certeza que deseja sair?',
                              style: TextStyle(color: Colors.white70),
                            ),
                            actions: [
                              TextButton(
                                child: Text('Cancelar'),
                                onPressed: () => Navigator.of(context).pop(),
                              ),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                ),
                                child: Text('Sair'),
                                onPressed: () async {
                                  // Fazer logout
                                  await _authService.logout();

                                  // Navegar para a tela de login
                                  Navigator.of(context).pushNamedAndRemoveUntil(
                                    '/login',
                                    (route) => false,
                                  );
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildMenuItem(
      BuildContext context, String title, IconData icon, String route) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
      title: Text(title, style: TextStyle(color: Colors.white)),
      onTap: () {
        if (kDebugMode) {
          print('Navegando para a rota: $route');
        }
        Navigator.pushNamed(context, route);
      },
    );
  }

  // Novo método para construir itens do submenu de administração
  Widget _buildSubmenuItem(
      BuildContext context, String title, IconData icon, String route) {
    return ListTile(
      dense: true, // Torna o item mais compacto
      contentPadding: EdgeInsets.only(left: 32.0, right: 16.0),
      leading:
          Icon(icon, color: Colors.white, size: 18), // Reduz o tamanho do ícone
      title: Text(
        title,
        style: TextStyle(
            color: Colors.white, fontSize: 13), // Reduz o tamanho da fonte
        overflow:
            TextOverflow.ellipsis, // Adiciona ellipsis para texto que não cabe
      ),
      onTap: () {
        if (kDebugMode) {
          print('Navegando para a rota: $route');
        }
        // Fechar o drawer se estiver aberto
        if (MediaQuery.of(context).size.width <= 600) {
          Navigator.pop(context);
        }
        Navigator.pushNamed(context, route);
      },
    );
  }

  Widget _buildInfoCard(
      String title, double value, Color color, double width, double height) {
    return Container(
      width: width,
      height: height,
      child: Card(
        color: color.withOpacity(0.2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        child: Padding(
          padding: EdgeInsets.all(4),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: TextStyle(color: Colors.white, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title == 'Empresas'
                      ? value.toStringAsFixed(0)
                      : currencyFormat.format(value),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExpensesGrid() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: MaterialStateProperty.all(Color(0xFF374151)),
        dataRowColor: MaterialStateProperty.all(Color(0xFF1F2937)),
        columns: [
          DataColumn(
              label: Text('Data Vencimento',
                  style: TextStyle(color: Colors.white))),
          DataColumn(
              label: Text('Categoria', style: TextStyle(color: Colors.white))),
          DataColumn(
              label: Text('Descrição', style: TextStyle(color: Colors.white))),
          DataColumn(
              label: Text('Valor', style: TextStyle(color: Colors.white))),
          DataColumn(
              label: Text('Status de Pagamento',
                  style: TextStyle(color: Colors.white))),
          DataColumn(
              label: Text('Data de Pagamento',
                  style: TextStyle(color: Colors.white))),
        ],
        rows: [
          _buildExpenseRow('2023-05-10', 'Alimentação', 'Supermercado', 500.00,
              'Pago', '2023-05-09'),
          _buildExpenseRow('2023-05-15', 'Transporte', 'Combustível', 200.00,
              'Pendente', '-'),
          _buildExpenseRow(
              '2023-05-20', 'Moradia', 'Aluguel', 1200.00, 'Pendente', '-'),
        ],
      ),
    );
  }

  DataRow _buildExpenseRow(String dueDate, String category, String description,
      double value, String status, String paymentDate) {
    return DataRow(
      cells: [
        DataCell(Text(dueDate, style: TextStyle(color: Colors.white))),
        DataCell(Text(category, style: TextStyle(color: Colors.white))),
        DataCell(Text(description, style: TextStyle(color: Colors.white))),
        DataCell(Text(currencyFormat.format(value),
            style: TextStyle(color: Colors.white))),
        DataCell(Text(status,
            style: TextStyle(
                color: status == 'Pago' ? Colors.green : Colors.red))),
        DataCell(Text(paymentDate, style: TextStyle(color: Colors.white))),
      ],
    );
  }
}
