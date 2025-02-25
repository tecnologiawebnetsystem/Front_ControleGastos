import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Expense {
  final DateTime dueDate;
  final String category;
  final String description;
  final double value;
  final DateTime? paymentDate;
  final String status;

  Expense({
    required this.dueDate,
    required this.category,
    required this.description,
    required this.value,
    this.paymentDate,
    required this.status,
  });
}

class ExpenseGrid extends StatelessWidget {
  final List<Expense> expenses;

  const ExpenseGrid({Key? key, required this.expenses}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: [
          DataColumn(label: Text('Vencimento')),
          DataColumn(label: Text('Categoria')),
          DataColumn(label: Text('Descrição')),
          DataColumn(label: Text('Valor')),
          DataColumn(label: Text('Pagamento')),
          DataColumn(label: Text('Status')),
        ],
        rows: expenses.map((expense) {
          return DataRow(cells: [
            DataCell(Text(DateFormat('dd/MM/yyyy').format(expense.dueDate))),
            DataCell(Text(expense.category)),
            DataCell(Text(expense.description)),
            DataCell(Text('R\$ ${expense.value.toStringAsFixed(2)}')),
            DataCell(Text(expense.paymentDate != null
                ? DateFormat('dd/MM/yyyy').format(expense.paymentDate!)
                : '-')),
            DataCell(Text(expense.status)),
          ]);
        }).toList(),
      ),
    );
  }
}

