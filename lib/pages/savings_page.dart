import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SavingsPage extends StatefulWidget {
  @override
  _SavingsPageState createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  TextEditingController _amountController = TextEditingController();
  bool isDeposit = true;
  DateTime transactionDate = DateTime.now();
  List<SavingsTransaction> transactions = [];
  List<SavingsTransaction> filteredTransactions = [];

  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    filteredTransactions = transactions;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addTransaction() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        transactions.add(SavingsTransaction(
          amount: double.parse(_amountController.text),
          isDeposit: isDeposit,
          date: transactionDate,
        ));
        _resetForm();
        _filterTransactions(_searchController.text);
      });
    }
  }

  void _resetForm() {
    setState(() {
      _amountController.clear();
      isDeposit = true;
      transactionDate = DateTime.now();
    });
  }

  void _filterTransactions(String query) {
    setState(() {
      filteredTransactions = transactions.where((transaction) {
        return _currencyFormat
                .format(transaction.amount)
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            (transaction.isDeposit ? 'Depósito' : 'Retirada')
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            _dateFormat
                .format(transaction.date)
                .toLowerCase()
                .contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1F2937),
      appBar: AppBar(
        title: Text('Poupança'),
        backgroundColor: Color(0xFF111827),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Pesquisar transações...',
                hintStyle: TextStyle(color: Colors.white54),
                prefixIcon: Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Color(0xFF374151),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterTransactions,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: Color(0xFF374151),
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _amountController,
                              decoration: InputDecoration(
                                labelText: 'Valor',
                                labelStyle: TextStyle(color: Colors.white),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                              ),
                              style: TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, insira um valor';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),
                            DropdownButtonFormField<bool>(
                              decoration: InputDecoration(
                                labelText: 'Tipo de Operação',
                                labelStyle: TextStyle(color: Colors.white),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                              ),
                              dropdownColor: Color(0xFF374151),
                              value: isDeposit,
                              items: [
                                DropdownMenuItem(
                                    child: Text('Depósito',
                                        style: TextStyle(color: Colors.white)),
                                    value: true),
                                DropdownMenuItem(
                                    child: Text('Retirada',
                                        style: TextStyle(color: Colors.white)),
                                    value: false),
                              ],
                              onChanged: (bool? value) {
                                setState(() {
                                  isDeposit = value!;
                                });
                              },
                              style: TextStyle(color: Colors.white),
                            ),
                            SizedBox(height: 16),
                            InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: transactionDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2101),
                                );
                                if (picked != null &&
                                    picked != transactionDate) {
                                  setState(() {
                                    transactionDate = picked;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Data da Transação',
                                  labelStyle: TextStyle(color: Colors.white),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      _dateFormat.format(transactionDate),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Icon(Icons.calendar_today,
                                        color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              child: Text('Registrar'),
                              onPressed: _addTransaction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  Text(
                    'Transações Registradas',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];
                      return Card(
                        color: Color(0xFF374151),
                        child: ListTile(
                          title: Text(
                            transaction.isDeposit ? 'Depósito' : 'Retirada',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${_dateFormat.format(transaction.date)} - ${_currencyFormat.format(transaction.amount)}',
                            style: TextStyle(color: Colors.white70),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                transactions.removeAt(index);
                                _filterTransactions(_searchController.text);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SavingsTransaction {
  final double amount;
  final bool isDeposit;
  final DateTime date;

  SavingsTransaction({
    required this.amount,
    required this.isDeposit,
    required this.date,
  });
}
