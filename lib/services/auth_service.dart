import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:controle_gasto_pessoal/models/auth_model.dart';
import 'package:controle_gasto_pessoal/services/api_service.dart';
import 'package:controle_gasto_pessoal/config/environment.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Singleton para garantir uma única instância do AuthService
class AuthService {
  // Instância singleton
  static final AuthService _instance = AuthService._internal();

  // Factory constructor para retornar a instância singleton
  factory AuthService() {
    return _instance;
  }

  // Construtor privado
  AuthService._internal() {
    // Inicialização assíncrona
    _initAsync();
  }

  // Inicialização assíncrona
  Future<void> _initAsync() async {
    await _loadSavedData();
  }

  final ApiService _apiService = ApiService();

  // Chaves para SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _userDataKey = 'user_data';

  // Armazenamento em memória
  String? _token;
  Map<String, dynamic>? _userData;

  // Flag para indicar se os dados foram carregados
  bool _dataLoaded = false;

  // Método para carregar dados salvos
  Future<void> _loadSavedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Carregar token
      final savedToken = prefs.getString(_tokenKey);
      if (savedToken != null) {
        _token = savedToken;
        _apiService.authToken = savedToken;

        if (kDebugMode) {
          print('Token carregado do armazenamento: $_token');
        }
      }

      // Carregar dados do usuário
      final savedUserData = prefs.getString(_userDataKey);
      if (savedUserData != null) {
        _userData = json.decode(savedUserData);

        if (kDebugMode) {
          print('Dados do usuário carregados do armazenamento: $_userData');
        }
      }

      _dataLoaded = true;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar dados salvos: $e');
      }
    }
  }

  // Método para garantir que os dados foram carregados
  Future<void> ensureInitialized() async {
    if (!_dataLoaded) {
      await _loadSavedData();
    }
  }

  // Método para salvar dados
  Future<void> _saveData() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Salvar token
      if (_token != null) {
        await prefs.setString(_tokenKey, _token!);
        if (kDebugMode) {
          print('Token salvo: $_token');
        }
      } else {
        await prefs.remove(_tokenKey);
        if (kDebugMode) {
          print('Token removido');
        }
      }

      // Salvar dados do usuário
      if (_userData != null) {
        final userDataJson = json.encode(_userData);
        await prefs.setString(_userDataKey, userDataJson);
        if (kDebugMode) {
          print('Dados do usuário salvos: $userDataJson');
        }
      } else {
        await prefs.remove(_userDataKey);
        if (kDebugMode) {
          print('Dados do usuário removidos');
        }
      }

      if (kDebugMode) {
        print('Dados salvos com sucesso');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao salvar dados: $e');
      }
    }
  }

  // Método para fazer login
  Future<AuthResponse> login(String email, String password) async {
    // Garantir que os dados foram carregados
    await ensureInitialized();

    // Em modo de desenvolvimento, use autenticação simulada
    if (AppConfig.isDevelopment && kIsWeb) {
      return _mockLogin(email, password);
    }

    try {
      final authRequest = AuthRequest(email: email, password: password);

      // Log da requisição
      if (kDebugMode) {
        print(
            'Enviando requisição de login: ${json.encode(authRequest.toJson())}');
      }

      final response =
          await _apiService.post('auth/login', authRequest.toJson());

      // Log da resposta bruta
      if (kDebugMode) {
        print('Resposta bruta do servidor: $response');
        if (response is Map) {
          print('Campos na resposta: ${response.keys.toList()}');
          if (response['data'] != null && response['data'] is Map) {
            print('Campos em data: ${(response['data'] as Map).keys.toList()}');
          }
          if (response['user'] != null && response['user'] is Map) {
            print('Campos em user: ${(response['user'] as Map).keys.toList()}');
          }
        }
      }

      // Verificar se a resposta é válida
      if (response == null) {
        return AuthResponse(
          success: false,
          message: 'Resposta vazia do servidor',
        );
      }

      // Tentar extrair os dados da resposta
      AuthResponse authResponse;
      try {
        authResponse = AuthResponse.fromJson(response);
      } catch (e) {
        if (kDebugMode) {
          print('Erro ao processar resposta: $e');
        }

        // Tentar criar uma resposta a partir de um formato diferente
        bool success = response['success'] ?? false;
        String? token = response['token'] ?? response['data']?['token'];
        Map<String, dynamic>? userData = response['data'] ?? response['user'];

        authResponse = AuthResponse(
          success: success,
          message: response['message'] ?? 'Formato de resposta desconhecido',
          token: token,
          userData: userData,
        );
      }

      if (authResponse.success && authResponse.token != null) {
        // Salvar o token e os dados do usuário
        _token = authResponse.token;

        // Garantir que userData seja um Map<String, dynamic>
        if (authResponse.userData != null) {
          _userData = Map<String, dynamic>.from(authResponse.userData!);

          // Normalizar os nomes dos campos para garantir consistência
          _normalizeUserData();

          // Adicionar campos que podem estar faltando
          _ensureRequiredFields(email);

          if (kDebugMode) {
            print('Dados do usuário definidos: $_userData');
          }
        } else {
          // Se não houver dados do usuário, criar um objeto completo
          _userData = {
            'id': 0,
            'usuarioid': 0,
            'nome': 'Usuário',
            'email': email,
            'login': email.split('@')[0],
            'adm': false,
            'ativo': true,
          };

          if (kDebugMode) {
            print('Dados do usuário criados manualmente: $_userData');
          }
        }

        // Configurar o token no ApiService para futuras requisições
        _apiService.authToken = authResponse.token;

        // Salvar dados no armazenamento persistente
        await _saveData();

        // Exibir informações detalhadas no log
        if (kDebugMode && _userData != null) {
          print('=== DADOS DO USUÁRIO LOGADO ===');
          print(
              'Usuario ID: ${_userData!['id'] ?? _userData!['usuarioid'] ?? 'N/A'}');
          print('Nome: ${_userData!['nome'] ?? _userData!['Nome'] ?? 'N/A'}');
          print(
              'E-mail: ${_userData!['email'] ?? _userData!['Email'] ?? 'N/A'}');
          print(
              'Login: ${_userData!['login'] ?? _userData!['Login'] ?? 'N/A'}');
          print('Adm: ${_userData!['adm'] ?? _userData!['Adm'] ?? 'N/A'}');
          print(
              'Ativo: ${_userData!['ativo'] ?? _userData!['Ativo'] ?? 'N/A'}');
          print('==============================');
        }
      }

      return authResponse;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao fazer login: $e');
      }
      return AuthResponse(
        success: false,
        message: 'Erro ao fazer login: $e',
      );
    }
  }

  // Método para garantir que todos os campos necessários estejam presentes
  void _ensureRequiredFields(String email) {
    if (_userData == null) return;

    // Lista de campos obrigatórios
    final requiredFields = {
      'id': 0,
      'usuarioid': _userData!['id'] ?? 0,
      'nome': 'Usuário',
      'email': email,
      'login': email.split('@')[0],
      'adm': false,
      'ativo': true,
    };

    // Adicionar campos que estão faltando
    requiredFields.forEach((key, defaultValue) {
      if (!_userData!.containsKey(key)) {
        _userData![key] = defaultValue;
      }
    });

    if (kDebugMode) {
      print('Campos obrigatórios garantidos: $_userData');
    }
  }

  // Método para normalizar os nomes dos campos nos dados do usuário
  void _normalizeUserData() {
    if (_userData == null) return;

    // Mapeamento de nomes de campos
    final Map<String, String> fieldMapping = {
      'usuarioid': 'id',
      'UsuarioID': 'id',
      'Nome': 'nome',
      'Email': 'email',
      'Login': 'login',
      'Adm': 'adm',
      'Ativo': 'ativo',
      'DataCriacao': 'dataCriacao',
    };

    // Criar um novo mapa para armazenar os dados normalizados
    final Map<String, dynamic> normalizedData = {};

    // Copiar os dados existentes
    _userData!.forEach((key, value) {
      normalizedData[key] = value;
    });

    // Normalizar os nomes dos campos
    fieldMapping.forEach((originalKey, normalizedKey) {
      if (_userData!.containsKey(originalKey)) {
        normalizedData[normalizedKey] = _userData![originalKey];
      }
    });

    // Atualizar o mapa de dados do usuário
    _userData = normalizedData;

    if (kDebugMode) {
      print('Dados do usuário normalizados: $_userData');
    }
  }

  // Método de login simulado para desenvolvimento
  Future<AuthResponse> _mockLogin(String email, String password) async {
    // Simular um atraso de rede
    await Future.delayed(Duration(seconds: 1));

    if (kDebugMode) {
      print('Usando login simulado para: $email');
    }

    // Aceitar qualquer credencial em modo de desenvolvimento
    final token = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';

    // Usar um nome mais realista para testes e adicionar os campos solicitados
    final userData = {
      'id': 1,
      'usuarioid': 1, // Adicionado para simular o campo do banco de dados
      'nome': 'João Silva',
      'email': email,
      'login': email.split('@')[0], // Usar parte do email como login
      'adm': true,
      'ativo': true,
    };

    // Salvar o token e os dados do usuário
    _token = token;
    _userData = userData;

    // Normalizar os dados do usuário
    _normalizeUserData();

    if (kDebugMode) {
      print('Token definido: $_token');
      print('Dados do usuário definidos: $_userData');
    }

    // Configurar o token no ApiService para futuras requisições
    _apiService.authToken = token;

    // Salvar dados no armazenamento persistente
    await _saveData();

    // Exibir informações detalhadas no log
    if (kDebugMode) {
      print('=== DADOS DO USUÁRIO LOGADO ===');
      print('Usuario ID: ${_userData!['id']}');
      print('Nome: ${_userData!['nome']}');
      print('E-mail: ${_userData!['email']}');
      print('Login: ${_userData!['login']}');
      print('Adm: ${_userData!['adm']}');
      print('Ativo: ${_userData!['ativo']}');
      print('==============================');
    }

    return AuthResponse(
      success: true,
      message: 'Login simulado bem-sucedido',
      token: token,
      userData: _userData,
    );
  }

  // Método para verificar se o usuário está autenticado
  bool isAuthenticated() {
    return _token != null;
  }

  // Método para obter o token salvo
  String? getToken() {
    return _token;
  }

  // Método para obter os dados do usuário
  Future<Map<String, dynamic>?> getUserData() async {
    // Garantir que os dados foram carregados
    await ensureInitialized();

    if (kDebugMode) {
      print('Retornando dados do usuário: $_userData');
    }
    return _userData;
  }

  // Método para obter os dados do usuário de forma síncrona
  Map<String, dynamic>? getUserDataSync() {
    if (kDebugMode) {
      print('Retornando dados do usuário (sync): $_userData');
    }
    return _userData;
  }

  // Método para definir dados do usuário diretamente (para testes)
  Future<void> setUserData(Map<String, dynamic> userData) async {
    _userData = userData;

    // Normalizar os dados do usuário
    _normalizeUserData();

    // Garantir que todos os campos necessários estejam presentes
    _ensureRequiredFields(userData['email'] ?? '');

    if (kDebugMode) {
      print('Dados do usuário definidos manualmente: $_userData');
    }

    await _saveData();

    // Exibir informações detalhadas no log
    if (kDebugMode) {
      print('=== DADOS DO USUÁRIO DEFINIDOS ===');
      print(
          'Usuario ID: ${_userData!['id'] ?? _userData!['usuarioid'] ?? 'N/A'}');
      print('Nome: ${_userData!['nome'] ?? _userData!['Nome'] ?? 'N/A'}');
      print('E-mail: ${_userData!['email'] ?? _userData!['Email'] ?? 'N/A'}');
      print('Login: ${_userData!['login'] ?? _userData!['Login'] ?? 'N/A'}');
      print('Adm: ${_userData!['adm'] ?? _userData!['Adm'] ?? 'N/A'}');
      print('Ativo: ${_userData!['ativo'] ?? _userData!['Ativo'] ?? 'N/A'}');
      print('==============================');
    }
  }

  // Método para fazer logout
  Future<void> logout() async {
    if (kDebugMode) {
      print('Realizando logout');
    }
    _token = null;
    _userData = null;
    _apiService.authToken = null;

    // Limpar dados do armazenamento persistente
    await _saveData();
  }

  // Método para buscar dados do usuário do servidor
  Future<bool> fetchUserData() async {
    if (_token == null) {
      if (kDebugMode) {
        print('Não é possível buscar dados do usuário sem token');
      }
      return false;
    }

    try {
      // Fazer uma requisição para obter os dados do usuário
      final response = await _apiService.get('usuarios/me');

      if (kDebugMode) {
        print('Resposta da busca de dados do usuário: $response');
      }

      if (response != null && (response is Map)) {
        Map<String, dynamic> userData;

        if (response.containsKey('data')) {
          userData = Map<String, dynamic>.from(response['data']);
        } else {
          userData = Map<String, dynamic>.from(response);
        }

        // Atualizar os dados do usuário
        _userData = userData;

        // Normalizar os nomes dos campos
        _normalizeUserData();

        // Garantir que todos os campos necessários estejam presentes
        _ensureRequiredFields(_userData?['email'] ?? '');

        // Salvar os dados atualizados
        await _saveData();

        if (kDebugMode) {
          print('Dados do usuário atualizados: $_userData');
        }

        return true;
      }

      return false;
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar dados do usuário: $e');
      }
      return false;
    }
  }
}
