import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomePage extends StatelessWidget {
  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1F2937),
      body: Row(
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
                  _buildMenuItem(
                      context, 'Categorias', Icons.category, '/categories'),
                ],
              ),
            ),
          // Conteúdo principal
          Expanded(
            child: Column(
              children: [
                // Barra superior com ícone de notificação e menu hamburguer para mobile
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
                      Icon(Icons.notifications, color: Colors.white),
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
                                MediaQuery.of(context).size.width > 600 ? 3 : 2;
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
                                _buildInfoCard('Poupança', 5000, Colors.blue,
                                    finalCardWidth, finalCardHeight),
                                _buildInfoCard(
                                    'Saldo',
                                    5000,
                                    Colors.greenAccent,
                                    finalCardWidth,
                                    finalCardHeight),
                                _buildInfoCard('Despesas', 3000, Colors.red,
                                    finalCardWidth, finalCardHeight),
                                _buildInfoCard('Salário', 7000, Colors.green,
                                    finalCardWidth, finalCardHeight),
                                _buildInfoCard('Descontos', 1000, Colors.teal,
                                    finalCardWidth, finalCardHeight),
                                _buildInfoCard('VA', 500, Colors.orange,
                                    finalCardWidth, finalCardHeight),
                                _buildInfoCard('Clientes', 5, Colors.purple,
                                    finalCardWidth, finalCardHeight),
                              ],
                            );
                          },
                        ),
                        SizedBox(height: 24),
                        Text(
                          'Despesas do Mês',
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
      // Drawer para menu em dispositivos móveis
      drawer: MediaQuery.of(context).size.width <= 600
          ? Drawer(
              child: Container(
                color: Color(0xFF111827),
                child: ListView(
                  children: [
                    DrawerHeader(
                      decoration: BoxDecoration(color: Color(0xFF1F2937)),
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
                    _buildMenuItem(
                        context, 'Categorias', Icons.category, '/categories'),
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
      onTap: () => Navigator.pushNamed(context, route),
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
                  title == 'Clientes'
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
