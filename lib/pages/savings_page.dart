import 'package:flutter/material.dart';

class SavingsPage extends StatefulWidget {
  @override
  _SavingsPageState createState() => _SavingsPageState();
}

class _SavingsPageState extends State<SavingsPage> {
  final _formKey = GlobalKey<FormState>();
  double amount = 0.0;
  bool isDeposit = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1F2937),
      appBar: AppBar(
        title: Text('Poupança'),
        backgroundColor: Color(0xFF111827),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Card(
          color: Color(0xFF374151),
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
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
                    onChanged: (value) =>
                        amount = double.tryParse(value) ?? 0.0,
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
                  ElevatedButton(
                    child: Text('Registrar'),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Implementar lógica de registro
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
