import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hello_world/models/transaction.dart';

class ApiService {
  static const String baseUrl =
      'https://api.example.com'; // Substitua pela URL da sua API

  Future<List<Transaction>> getTransactions() async {
    final response = await http.get(Uri.parse('$baseUrl/transactions'));

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Transaction.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar transações');
    }
  }

  Future<Transaction> addTransaction(Transaction transaction) async {
    final response = await http.post(
      Uri.parse('$baseUrl/transactions'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(transaction.toJson()),
    );

    if (response.statusCode == 201) {
      return Transaction.fromJson(json.decode(response.body));
    } else {
      throw Exception('Falha ao adicionar transação');
    }
  }
}
