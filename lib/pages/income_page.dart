import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class IncomePage extends StatefulWidget {
  @override
  _IncomePageState createState() => _IncomePageState();
}

class _IncomePageState extends State<IncomePage> {
  final _formKey = GlobalKey<FormState>();
  final _dateFormat = DateFormat('dd/MM/yyyy');
  final _currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

  bool isSalary = false;
  String? selectedCompany;
  TextEditingController _descriptionController = TextEditingController();
  TextEditingController _amountController = TextEditingController();
  DateTime receiptDate = DateTime.now();
  List<Income> incomes = [];
  List<Income> filteredIncomes = [];

  TextEditingController _searchController = TextEditingController();

  List<String> companies = ['Empresa A', 'Empresa B', 'Empresa C'];

  @override
  void initState() {
    super.initState();
    filteredIncomes = incomes;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addIncome() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        incomes.add(Income(
          isSalary: isSalary,
          company: isSalary ? selectedCompany : null,
          description: isSalary ? null : _descriptionController.text,
          amount: double.parse(_amountController.text),
          receiptDate: receiptDate,
        ));
        _resetForm();
      });
    }
  }

  void _resetForm() {
    setState(() {
      isSalary = false;
      selectedCompany = null;
      _descriptionController.clear();
      _amountController.clear();
      receiptDate = DateTime.now();
    });
  }

  void _filterIncomes(String query) {
    setState(() {
      filteredIncomes = incomes.where((income) {
        return (income.description
                    ?.toLowerCase()
                    .contains(query.toLowerCase()) ??
                false) ||
            (income.company?.toLowerCase().contains(query.toLowerCase()) ??
                false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1F2937),
      appBar: AppBar(
        title: Text('Entradas'),
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
                hintText: 'Pesquisar entradas...',
                hintStyle: TextStyle(color: Colors.white54),
                prefixIcon: Icon(Icons.search, color: Colors.white),
                filled: true,
                fillColor: Color(0xFF374151),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: _filterIncomes,
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
                            SwitchListTile(
                              title: Text('Salário',
                                  style: TextStyle(color: Colors.white)),
                              value: isSalary,
                              onChanged: (bool value) {
                                setState(() {
                                  isSalary = value;
                                  if (!value) {
                                    selectedCompany = null;
                                  }
                                });
                              },
                            ),
                            if (isSalary)
                              DropdownButtonFormField<String>(
                                decoration: InputDecoration(
                                  labelText: 'Empresa',
                                  labelStyle: TextStyle(color: Colors.white),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),
                                dropdownColor: Color(0xFF374151),
                                value: selectedCompany,
                                items: companies.map((String company) {
                                  return DropdownMenuItem<String>(
                                    value: company,
                                    child: Text(company,
                                        style: TextStyle(color: Colors.white)),
                                  );
                                }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    selectedCompany = newValue;
                                  });
                                },
                                style: TextStyle(color: Colors.white),
                              )
                            else
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
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Por favor, insira uma descrição';
                                  }
                                  return null;
                                },
                              ),
                            SizedBox(height: 16),
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
                            InkWell(
                              onTap: () async {
                                final DateTime? picked = await showDatePicker(
                                  context: context,
                                  initialDate: receiptDate,
                                  firstDate: DateTime(2000),
                                  lastDate: DateTime(2101),
                                );
                                if (picked != null && picked != receiptDate) {
                                  setState(() {
                                    receiptDate = picked;
                                  });
                                }
                              },
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Data',
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
                                      _dateFormat.format(receiptDate),
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
                              child: Text('Adicionar'),
                              onPressed: _addIncome,
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
                    'Itens Registrados',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: filteredIncomes.length,
                    itemBuilder: (context, index) {
                      final income = filteredIncomes[index];
                      return Card(
                        color: Color(0xFF374151),
                        child: ListTile(
                          title: Text(
                            income.isSalary
                                ? 'Salário - ${income.company}'
                                : 'Descrição - ${income.description}',
                            style: TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            '${_dateFormat.format(income.receiptDate)} - ${_currencyFormat.format(income.amount)}',
                            style: TextStyle(color: Colors.white70),
                          ),
                          trailing: IconButton(
                            icon: Icon(Icons.delete, color: Colors.white),
                            onPressed: () {
                              setState(() {
                                incomes.removeAt(index);
                                filteredIncomes = incomes;
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

class Income {
  final bool isSalary;
  final String? company;
  final String? description;
  final double amount;
  final DateTime receiptDate;

  Income({
    required this.isSalary,
    this.company,
    this.description,
    required this.amount,
    required this.receiptDate,
  });
}
