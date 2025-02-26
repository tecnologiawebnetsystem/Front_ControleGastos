import 'package:flutter/material.dart';
import 'package:controle_gasto_pessoal/models/bank.dart';

class BankRegistrationPage extends StatefulWidget {
  @override
  _BankRegistrationPageState createState() => _BankRegistrationPageState();
}

class _BankRegistrationPageState extends State<BankRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  String? selectedBank;
  TextEditingController _agencyController = TextEditingController();
  TextEditingController _accountController = TextEditingController();
  TextEditingController _pixController = TextEditingController();
  List<RegisteredBank> registeredBanks = [];
  TextEditingController _searchController = TextEditingController();

  final List<Bank> bankList = [
    Bank(code: '001', name: 'Banco do Brasil'),
    Bank(code: '033', name: 'Santander'),
    Bank(code: '341', name: 'Itaú'),
    Bank(code: '104', name: 'Caixa Econômica Federal'),
    Bank(code: '237', name: 'Bradesco'),
  ];

  @override
  void dispose() {
    _agencyController.dispose();
    _accountController.dispose();
    _pixController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addBank() {
    if (_formKey.currentState!.validate() && selectedBank != null) {
      setState(() {
        registeredBanks.add(RegisteredBank(
          bank: bankList.firstWhere((bank) => bank.code == selectedBank),
          agency: _agencyController.text,
          account: _accountController.text,
          pix: _pixController.text,
        ));
      });
      _resetForm();
    }
  }

  void _resetForm() {
    setState(() {
      selectedBank = null;
      _agencyController.clear();
      _accountController.clear();
      _pixController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1F2937),
      appBar: AppBar(
        title: Text('Cadastro de Bancos'),
        backgroundColor: Color(0xFF111827),
      ),
      body: SingleChildScrollView(
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
                          labelText: 'Banco',
                          labelStyle: TextStyle(color: Colors.white),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        dropdownColor: Color(0xFF374151),
                        value: selectedBank,
                        items: bankList.map((Bank bank) {
                          return DropdownMenuItem<String>(
                            value: bank.code,
                            child: Text(bank.name,
                                style: TextStyle(color: Colors.white)),
                          );
                        }).toList(),
                        onChanged: (String? newValue) {
                          setState(() {
                            selectedBank = newValue;
                          });
                        },
                        style: TextStyle(color: Colors.white),
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Agência',
                          labelStyle: TextStyle(color: Colors.white),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        controller: _agencyController,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Conta',
                          labelStyle: TextStyle(color: Colors.white),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        controller: _accountController,
                      ),
                      SizedBox(height: 16),
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'PIX',
                          labelStyle: TextStyle(color: Colors.white),
                          border: OutlineInputBorder(),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.white),
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                        controller: _pixController,
                      ),
                      SizedBox(height: 16),
                      ElevatedButton(
                        child: Text('Cadastrar'),
                        onPressed: _addBank,
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
              'Bancos Cadastrados',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              itemCount: registeredBanks.length,
              itemBuilder: (context, index) {
                final bank = registeredBanks[index];
                return Card(
                  color: Color(0xFF374151),
                  child: ListTile(
                    title: Text(bank.bank.name,
                        style: TextStyle(color: Colors.white)),
                    subtitle: Text(
                      'Agência: ${bank.agency}, Conta: ${bank.account}',
                      style: TextStyle(color: Colors.white70),
                    ),
                    trailing: IconButton(
                      icon: Icon(Icons.delete, color: Colors.white),
                      onPressed: () {
                        setState(() {
                          registeredBanks.removeAt(index);
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
    );
  }
}

class RegisteredBank {
  final Bank bank;
  final String agency;
  final String account;
  final String pix;

  RegisteredBank({
    required this.bank,
    required this.agency,
    required this.account,
    required this.pix,
  });
}
