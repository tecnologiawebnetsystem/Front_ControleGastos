import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpensesPage extends StatefulWidget {
  @override
  _ExpensesPageState createState() => _ExpensesPageState();
}

class _ExpensesPageState extends State<ExpensesPage> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  String? category;
  TextEditingController _descriptionController = TextEditingController();
  bool isInstallment = false;
  TextEditingController _installmentsController = TextEditingController();
  DateTime dueDate = DateTime.now();
  TextEditingController _totalAmountController = TextEditingController();
  List<Expense> expenses = [];
  List<Expense> filteredExpenses = [];

  TextEditingController _searchController = TextEditingController();

  List<String> categories = [
    'Alimentação',
    'Transporte',
    'Moradia',
    'Saúde',
    'Educação',
    'Lazer',
    'Outros'
  ];

  @override
  void initState() {
    super.initState();
    filteredExpenses = expenses;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _installmentsController.dispose();
    _totalAmountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addExpense() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        double totalAmount =
            double.tryParse(_totalAmountController.text) ?? 0.0;
        int installments = int.tryParse(_installmentsController.text) ?? 1;
        double installmentAmount =
            isInstallment ? totalAmount / installments : totalAmount;

        for (int i = 0; i < (isInstallment ? installments : 1); i++) {
          expenses.add(Expense(
            category: category!,
            description: _descriptionController.text,
            dueDate: dueDate.add(Duration(days: 30 * i)),
            totalAmount: totalAmount,
            installmentAmount: installmentAmount,
            installmentNumber: isInstallment ? i + 1 : null,
            totalInstallments: isInstallment ? installments : null,
            isPaid: false,
            paymentDate: null,
          ));
        }
        _resetForm();
      });
    }
  }

  void _resetForm() {
    setState(() {
      category = null;
      _descriptionController.clear();
      isInstallment = false;
      _installmentsController.clear();
      dueDate = DateTime.now();
      _totalAmountController.clear();
    });
  }

  void _filterExpenses(String query) {
    setState(() {
      filteredExpenses = expenses.where((expense) {
        return expense.description
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            expense.category.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1F2937),
      appBar: AppBar(
        title: Text('Despesas'),
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
                hintText: 'Pesquisar despesas...',
                hintStyle: TextStyle(color: Colors.white54),
                prefixIcon: Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Color(0xFF374151),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterExpenses,
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
                            DropdownButtonFormField<String>(
                              decoration: InputDecoration(
                                labelText: 'Categoria',
                                labelStyle: TextStyle(color: Colors.white),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                              ),
                              dropdownColor: Color(0xFF374151),
                              value: category,
                              items: categories.map((String value) {
                                return DropdownMenuItem<String>(
                                  value: value,
                                  child: Text(value,
                                      style: TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  category = newValue;
                                });
                              },
                              style: TextStyle(color: Colors.white),
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _descriptionController,
                              decoration: InputDecoration(
                                labelText: 'Descrição',
                                labelStyle: TextStyle(color: Colors.white),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                              ),
                              style: TextStyle(color: Colors.white),
                            ),
                            SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: SwitchListTile(
                                    title: Text('Parcelado',
                                        style: TextStyle(color: Colors.white)),
                                    value: isInstallment,
                                    onChanged: (bool value) {
                                      setState(() {
                                        isInstallment = value;
                                      });
                                    },
                                  ),
                                ),
                                if (isInstallment)
                                  Expanded(
                                    child: TextFormField(
                                      controller: _installmentsController,
                                      decoration: InputDecoration(
                                        labelText: 'Parcelas',
                                        labelStyle:
                                            TextStyle(color: Colors.white),
                                        border: OutlineInputBorder(),
                                        enabledBorder: OutlineInputBorder(
                                          borderSide:
                                              BorderSide(color: Colors.white),
                                        ),
                                      ),
                                      style: TextStyle(color: Colors.white),
                                      keyboardType: TextInputType.number,
                                    ),
                                  ),
                              ],
                            ),
                            SizedBox(height: 16),
                            InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: dueDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2101),
                                );
                                if (picked != null && picked != dueDate) {
                                  setState(() {
                                    dueDate = picked;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Data de Vencimento',
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
                                      _dateFormat.format(dueDate),
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    Icon(Icons.calendar_today,
                                        color: Colors.white),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: 16),
                            TextFormField(
                              controller: _totalAmountController,
                              decoration: InputDecoration(
                                labelText: 'Valor Total',
                                labelStyle: TextStyle(color: Colors.white),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                              ),
                              style: TextStyle(color: Colors.white),
                              keyboardType: TextInputType.number,
                            ),
                            SizedBox(height: 16),
                            ElevatedButton(
                              child: Text('Adicionar Despesa'),
                              onPressed: _addExpense,
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
                    'Despesas Cadastradas',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: filteredExpenses.length,
                    itemBuilder: (context, index) {
                      final expense = filteredExpenses[index];
                      return Card(
                        color: Color(0xFF374151),
                        child: ListTile(
                          title: Text(expense.description,
                              style: TextStyle(color: Colors.white)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${expense.category} - ${_dateFormat.format(expense.dueDate)}',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                expense.installmentNumber != null
                                    ? 'Parcela ${expense.installmentNumber}/${expense.totalInstallments} - ${_currencyFormat.format(expense.installmentAmount)}'
                                    : _currencyFormat
                                        .format(expense.totalAmount),
                                style: TextStyle(color: Colors.white70),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: expense.isPaid,
                                onChanged: (bool? value) {
                                  setState(() {
                                    expense.isPaid = value!;
                                    expense.paymentDate =
                                        value ? DateTime.now() : null;
                                  });
                                },
                                fillColor:
                                    MaterialStateProperty.resolveWith<Color>(
                                        (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.disabled)) {
                                    return Colors.orange.withOpacity(.32);
                                  }
                                  return Colors.orange;
                                }),
                              ),
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    expenses.removeAt(index);
                                  });
                                },
                              ),
                            ],
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

class Expense {
  String category;
  String description;
  DateTime dueDate;
  double totalAmount;
  double installmentAmount;
  int? installmentNumber;
  int? totalInstallments;
  bool isPaid;
  DateTime? paymentDate;

  Expense({
    required this.category,
    required this.description,
    required this.dueDate,
    required this.totalAmount,
    required this.installmentAmount,
    this.installmentNumber,
    this.totalInstallments,
    required this.isPaid,
    this.paymentDate,
  });
}
