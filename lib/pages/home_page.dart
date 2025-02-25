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
                ListTile(
                  leading: Icon(Icons.account_balance, color: Colors.white),
                  title: Text('Bancos', style: TextStyle(color: Colors.white)),
                  onTap: () =>
                      Navigator.pushNamed(context, '/bank_registration'),
                ),
                ListTile(
                  leading: Icon(Icons.business, color: Colors.white),
                  title:
                      Text('Empresas', style: TextStyle(color: Colors.white)),
                  onTap: () =>
                      Navigator.pushNamed(context, '/company_registration'),
                ),
                ListTile(
                  leading: Icon(Icons.savings, color: Colors.white),
                  title:
                      Text('Poupança', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pushNamed(context, '/savings'),
                ),
                ListTile(
                  leading: Icon(Icons.category, color: Colors.white),
                  title:
                      Text('Categorias', style: TextStyle(color: Colors.white)),
                  onTap: () => Navigator.pushNamed(context, '/categories'),
                ),
              ],
            ),
          ),
          // Conteúdo principal
          Expanded(
            child: Column(
              children: [
                // Barra superior com ícone de notificação
                Container(
                  height: 60,
                  color: Color(0xFF111827),
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: Icon(Icons.notifications, color: Colors.white),
                ),
                // Conteúdo rolável
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Molduras
                        GridView.count(
                          crossAxisCount: 3,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          children: [
                            _buildInfoCard('Poupança', 5000, Colors.blue),
                            _buildInfoCard('Despesas', 3000, Colors.red),
                            _buildInfoCard('Entrada', 7000, Colors.green),
                            _buildInfoCard('VA', 500, Colors.orange),
                            _buildInfoCard('Clientes', 5, Colors.purple),
                            _buildInfoCard('Descontos', 1000, Colors.teal),
                          ],
                        ),
                        SizedBox(height: 24),
                        // Grid de despesas
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
    );
  }

  Widget _buildInfoCard(String title, double value, Color color) {
    return Card(
      color: color.withOpacity(0.2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              title,
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            SizedBox(height: 8),
            Text(
              title == 'Clientes'
                  ? value.toStringAsFixed(0)
                  : currencyFormat.format(value),
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
          ],
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
          // Adicione mais linhas conforme necessário
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
