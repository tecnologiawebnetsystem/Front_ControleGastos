import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:controle_gasto_pessoal/models/bank.dart';

class BankApiService {
  static const String baseUrl = 'https://brasilapi.com.br/api/banks/v1';

  Future<List<Bank>> getBanks() async {
    final response = await http.get(Uri.parse(baseUrl));

    if (response.statusCode == 200) {
      List<dynamic> jsonList = json.decode(response.body);
      return jsonList.map((json) => Bank.fromJson(json)).toList();
    } else {
      throw Exception('Falha ao carregar bancos');
    }
  }
}
