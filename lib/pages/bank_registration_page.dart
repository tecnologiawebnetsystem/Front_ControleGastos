import 'package:flutter/material.dart';
import 'package:controle_gasto_pessoal/models/bank.dart';
import 'package:controle_gasto_pessoal/models/banco_model.dart';
import 'package:controle_gasto_pessoal/services/banco_service.dart';
import 'package:controle_gasto_pessoal/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:controle_gasto_pessoal/config/environment.dart';

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
  List<BancoModel> registeredBanks = [];
  bool isLoading = true;
  bool isEditing = false;
  int? editingBancoId;

  late BancoService _bancoService;
  int _usuarioId = 0; // Será preenchido com o ID real do usuário
  String? _token;
  Map<String, dynamic>? _userData;

  final List<Bank> bankList = [
    Bank(code: '001', name: 'Banco do Brasil'),
    Bank(code: '033', name: 'Santander'),
    Bank(code: '341', name: 'Itaú'),
    Bank(code: '104', name: 'Caixa Econômica Federal'),
    Bank(code: '237', name: 'Bradesco'),
    // Bancos digitais
    Bank(code: '260', name: 'Nubank'),
    Bank(code: '077', name: 'Inter'),
    Bank(code: '336', name: 'C6 Bank'),
    Bank(code: '323', name: 'Mercado Pago'),
    Bank(code: '208', name: 'BTG Pactual'),
    Bank(code: '655', name: 'Neon'),
    Bank(code: '290', name: 'PagBank (PagSeguro)'),
    Bank(code: '197', name: 'Stone'),
    Bank(code: '403', name: 'Cora'),
    Bank(code: '212', name: 'Banco Original'),
    Bank(code: '756', name: 'Sicoob'),
    Bank(code: '748', name: 'Sicredi'),
    Bank(code: '422', name: 'Safra'),
    Bank(code: '021', name: 'Banestes'),
    Bank(code: '085', name: 'Next'),
    Bank(code: '380', name: 'PicPay'),
    Bank(code: '735', name: 'Banco Neon'),
    Bank(code: '188', name: 'Ame Digital'),
    Bank(code: '280', name: 'Will Bank'),
    Bank(code: '301', name: 'BPP Bank'),
  ];

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  void _showSuccessMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _resetForm() {
    setState(() {
      isEditing = false;
      editingBancoId = null;
      selectedBank = null;
      _agencyController.clear();
      _accountController.clear();
      _pixController.clear();
    });
  }

  Future<void> _initializeData() async {
    try {
      // Obter o token de autenticação
      final authService = AuthService();
      _token = authService.getToken();

      if (_token == null) {
        if (kDebugMode) {
          print('Token não encontrado. Redirecionando para login...');
        }
        Future.delayed(Duration.zero, () {
          Navigator.of(context).pushReplacementNamed('/login');
        });
        return;
      }

      // Buscar dados do usuário diretamente da API
      await _fetchUserData();

      if (_userData == null) {
        _showErrorMessage('Não foi possível obter os dados do usuário');
        setState(() {
          isLoading = false;
        });
        return;
      }

      // Extrair o ID do usuário dos dados obtidos
      _usuarioId = _extractUserId(_userData!);

      if (kDebugMode) {
        print('ID do usuário obtido da API: $_usuarioId');
      }

      // Inicializar o serviço de banco com o token
      _bancoService = BancoService(token: _token!);

      // Carregar os bancos do usuário
      await _loadBancos();
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao inicializar dados: $e');
      }
      _showErrorMessage('Erro ao inicializar: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  // Método para buscar dados do usuário diretamente da API
  Future<void> _fetchUserData() async {
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiBaseUrl}/usuarios/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (kDebugMode) {
        print('Status code da requisição de usuário: ${response.statusCode}');
        print('Resposta da requisição de usuário: ${response.body}');
      }

      if (response.statusCode == 200) {
        _userData = json.decode(response.body);
      } else {
        // Se falhar, tente um endpoint alternativo
        final alternativeResponse = await http.get(
          Uri.parse('${AppConfig.apiBaseUrl}/usuarios/current'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $_token',
          },
        );

        if (kDebugMode) {
          print(
              'Status code da requisição alternativa: ${alternativeResponse.statusCode}');
          print(
              'Resposta da requisição alternativa: ${alternativeResponse.body}');
        }

        if (alternativeResponse.statusCode == 200) {
          _userData = json.decode(alternativeResponse.body);
        } else {
          throw Exception(
              'Falha ao obter dados do usuário: ${response.statusCode}');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao buscar dados do usuário: $e');
      }
      throw Exception('Erro ao buscar dados do usuário: $e');
    }
  }

  // Método para extrair o ID do usuário dos dados obtidos
  int _extractUserId(Map<String, dynamic> userData) {
    // Tenta obter o ID do usuário de diferentes campos possíveis
    final id = userData['id'] ??
        userData['Id'] ??
        userData['ID'] ??
        userData['usuarioId'] ??
        userData['UsuarioId'] ??
        userData['usuarioid'] ??
        userData['UsuarioID'];

    if (id == null) {
      throw Exception('ID do usuário não encontrado nos dados');
    }

    return int.parse(id.toString());
  }

  Future<void> _loadBancos() async {
    if (_token == null) {
      _showErrorMessage('Token não encontrado');
      setState(() {
        isLoading = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // Limpar o cache HTTP para garantir dados frescos
      http.Client().close();

      // Usar o serviço para carregar os bancos
      final bancos = await _bancoService.getBancos(_usuarioId);

      if (kDebugMode) {
        print('Bancos carregados: ${bancos.length}');
        for (var banco in bancos) {
          print(
              'Banco: ${banco.bancoId} - ${banco.nome} - ${banco.agencia} - ${banco.conta}');
        }
      }

      setState(() {
        registeredBanks = bancos;
        isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar bancos: $e');
      }

      setState(() {
        registeredBanks = [];
        isLoading = false;
      });

      _showErrorMessage('Erro ao carregar bancos: $e');
    }
  }

  @override
  void dispose() {
    _agencyController.dispose();
    _accountController.dispose();
    _pixController.dispose();
    super.dispose();
  }

  void _addOrUpdateBank() async {
    if (_formKey.currentState!.validate() && selectedBank != null) {
      setState(() {
        isLoading = true; // Mostrar indicador de carregamento
      });

      final selectedBankInfo =
          bankList.firstWhere((bank) => bank.code == selectedBank);

      try {
        if (isEditing && editingBancoId != null) {
          // Atualizar banco existente
          final bancoToUpdate = BancoModel(
            bancoId: editingBancoId,
            usuarioId: _usuarioId,
            nome: selectedBankInfo.name,
            codigo: selectedBankInfo.code,
            agencia: _agencyController.text,
            conta: _accountController.text,
            pix: _pixController.text,
          );

          if (kDebugMode) {
            print('Atualizando banco: ${json.encode(bancoToUpdate.toJson())}');
          }

          // Usar o serviço para atualizar o banco
          final updatedBanco = await _bancoService.updateBanco(bancoToUpdate);

          if (kDebugMode) {
            print(
                'Banco atualizado: ${updatedBanco.bancoId} - ${updatedBanco.nome}');
          }

          _showSuccessMessage('Banco atualizado com sucesso!');

          // Forçar uma recarga completa dos bancos
          await Future.delayed(Duration(
              milliseconds:
                  500)); // Pequeno atraso para garantir que a API processou a atualização
          await _loadBancos();

          _resetForm();
        } else {
          // Criar novo banco
          final newBanco = BancoModel(
            usuarioId: _usuarioId,
            nome: selectedBankInfo.name,
            codigo: selectedBankInfo.code,
            agencia: _agencyController.text,
            conta: _accountController.text,
            pix: _pixController.text,
          );

          if (kDebugMode) {
            print('Criando banco: ${json.encode(newBanco.toJson())}');
          }

          // Usar o serviço para criar o banco
          final createdBanco = await _bancoService.createBanco(newBanco);

          if (kDebugMode) {
            print(
                'Banco criado: ${createdBanco.bancoId} - ${createdBanco.nome}');
          }

          _showSuccessMessage('Banco cadastrado com sucesso!');

          // Forçar uma recarga completa dos bancos
          await Future.delayed(Duration(
              milliseconds:
                  500)); // Pequeno atraso para garantir que a API processou a criação
          await _loadBancos();

          _resetForm();
        }
      } catch (e) {
        if (kDebugMode) {
          print('Erro ao ${isEditing ? 'atualizar' : 'cadastrar'} banco: $e');
        }
        _showErrorMessage(
            'Erro ao ${isEditing ? 'atualizar' : 'cadastrar'} banco: $e');
      } finally {
        setState(() {
          isLoading = false; // Esconder indicador de carregamento
        });
      }
    }
  }

  void _editBank(BancoModel banco) {
    // Encontrar o banco na lista de bancos disponíveis
    final bankIndex = bankList.indexWhere((b) => b.code == banco.codigo);

    if (bankIndex != -1) {
      setState(() {
        isEditing = true;
        editingBancoId = banco.bancoId;
        selectedBank = banco.codigo;
        _agencyController.text = banco.agencia;
        _accountController.text = banco.conta;
        _pixController.text = banco.pix;
      });
    } else {
      _showErrorMessage('Banco não encontrado na lista de bancos disponíveis');
    }
  }

  void _deleteBank(BancoModel banco) async {
    try {
      // Usar o serviço para excluir o banco
      await _bancoService.deleteBanco(banco.bancoId!, _usuarioId);

      _showSuccessMessage('Banco excluído com sucesso!');
      await _loadBancos();
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao excluir banco: $e');
      }
      _showErrorMessage('Erro ao excluir banco: $e');
    }
  }

  void _showDeleteConfirmation(BancoModel banco) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF374151),
          title:
              Text('Confirmar exclusão', style: TextStyle(color: Colors.white)),
          content: Text(
            'Deseja realmente excluir o banco ${banco.nome}?',
            style: TextStyle(color: Colors.white),
          ),
          actions: [
            TextButton(
              child: Text('Cancelar', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Excluir', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteBank(banco);
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1F2937),
      appBar: AppBar(
        title: Text('Cadastro de Bancos'),
        backgroundColor: Color(0xFF111827),
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
                            Text(
                              isEditing ? 'Editar Banco' : 'Novo Banco',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),
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
                                  child: Text('${bank.code} - ${bank.name}',
                                      style: TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  selectedBank = newValue;
                                });
                              },
                              style: TextStyle(color: Colors.white),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, selecione um banco';
                                }
                                return null;
                              },
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, informe a agência';
                                }
                                return null;
                              },
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
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, informe a conta';
                                }
                                return null;
                              },
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
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  child: Text(
                                      isEditing ? 'Atualizar' : 'Cadastrar'),
                                  onPressed: _addOrUpdateBank,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        isEditing ? Colors.orange : Colors.blue,
                                  ),
                                ),
                                if (isEditing)
                                  ElevatedButton(
                                    child: Text('Cancelar'),
                                    onPressed: _resetForm,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.grey,
                                    ),
                                  ),
                              ],
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
                  registeredBanks.isEmpty
                      ? Center(
                          child: Text(
                            'Nenhum banco cadastrado',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: registeredBanks.length,
                          itemBuilder: (context, index) {
                            final banco = registeredBanks[index];
                            return Card(
                              color: Color(0xFF374151),
                              child: ListTile(
                                title: Text('${banco.codigo} - ${banco.nome}',
                                    style: TextStyle(color: Colors.white)),
                                subtitle: Text(
                                  'Agência: ${banco.agencia}, Conta: ${banco.conta}',
                                  style: TextStyle(color: Colors.white70),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon:
                                          Icon(Icons.edit, color: Colors.white),
                                      onPressed: () => _editBank(banco),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete,
                                          color: Colors.white),
                                      onPressed: () =>
                                          _showDeleteConfirmation(banco),
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
    );
  }
}
