import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

Future<bool> testApiConnection() async {
  try {
    // Teste com uma API pública
    final response = await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts/1'));
    
    if (kDebugMode) {
      print('Teste de API - Status Code: ${response.statusCode}');
      print('Teste de API - Response: ${response.body}');
    }
    
    return response.statusCode >= 200 && response.statusCode < 300;
  } catch (e) {
    if (kDebugMode) {
      print('Teste de API - Erro: $e');
    }
    return false;
  }
}

