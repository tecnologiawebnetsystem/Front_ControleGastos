import 'package:flutter/material.dart';
import 'package:controle_gasto_pessoal/models/empresa_model.dart';
import 'package:controle_gasto_pessoal/models/contract_type.dart';
import 'package:controle_gasto_pessoal/models/banco_model.dart';
import 'package:controle_gasto_pessoal/services/empresa_service.dart';
import 'package:controle_gasto_pessoal/services/auth_service.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:controle_gasto_pessoal/config/environment.dart';
import 'package:intl/intl.dart';

class CompanyRegistrationPage extends StatefulWidget {
  @override
  _CompanyRegistrationPageState createState() =>
      _CompanyRegistrationPageState();
}

class _CompanyRegistrationPageState extends State<CompanyRegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _nomeController = TextEditingController();
  final _clienteController = TextEditingController();
  final _valorController = TextEditingController();
  final _valorVAController = TextEditingController();

  int? selectedTipoContratacaoId;
  int? selectedBancoId;
  int? selectedDiaPagamento1;
  int? selectedDiaPagamento2;
  bool ativo = true;

  List<EmpresaModel> registeredEmpresas = [];
  List<ContractType> tiposContratacao = [];
  List<BancoModel> bancos = [];
  bool isLoading = true;
  bool isEditing = false;
  int? editingEmpresaId;

  late EmpresaService _empresaService;
  int _usuarioId = 0;
  String? _token;
  Map<String, dynamic>? _userData;

  final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

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
      editingEmpresaId = null;
      _nomeController.clear();
      _clienteController.clear();
      _valorController.clear();
      _valorVAController.clear();
      selectedTipoContratacaoId = null;
      selectedBancoId = null;
      selectedDiaPagamento1 = null;
      selectedDiaPagamento2 = null;
      ativo = true;
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

      // Buscar dados do usuário
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

      // Inicializar o serviço de empresa com o token
      _empresaService = EmpresaService(token: _token!);

      // Carregar os tipos de contratação
      await _loadTiposContratacao();

      // Carregar os bancos
      await _loadBancos();

      // Carregar as empresas do usuário
      await _loadEmpresas();
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

  Future<void> _loadTiposContratacao() async {
    if (_token == null) {
      _showErrorMessage('Token não encontrado');
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      // Usar o serviço para carregar os tipos de contratação
      final tipos = await _empresaService.getTiposContratacao();

      if (kDebugMode) {
        print('Tipos de contratação carregados: ${tipos.length}');
        for (var tipo in tipos) {
          print('Tipo: ${tipo.id} - ${tipo.description}');
        }
      }

      setState(() {
        tiposContratacao = tipos;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar tipos de contratação: $e');
      }

      _showErrorMessage('Erro ao carregar tipos de contratação: $e');
    }
  }

  Future<void> _loadBancos() async {
    if (_token == null) {
      _showErrorMessage('Token não encontrado');
      setState(() {
        isLoading = false;
      });
      return;
    }

    try {
      // Usar o serviço para carregar os bancos
      final bancosList = await _empresaService.getBancos(_usuarioId);

      if (kDebugMode) {
        print('Bancos carregados: ${bancosList.length}');
        for (var banco in bancosList) {
          print('Banco: ${banco.bancoId} - ${banco.nome}');
        }
      }

      setState(() {
        bancos = bancosList;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar bancos: $e');
      }

      _showErrorMessage('Erro ao carregar bancos: $e');
    }
  }

  Future<void> _loadEmpresas() async {
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

      // Usar o serviço para carregar as empresas
      final empresas = await _empresaService.getEmpresas(_usuarioId);

      if (kDebugMode) {
        print('Empresas carregadas: ${empresas.length}');
        for (var empresa in empresas) {
          print(
              'Empresa: ${empresa.empresaId} - ${empresa.nome} - ${empresa.cliente}');
          print('  DiaPagamento1: ${empresa.diaPagamento1}');
          print('  DiaPagamento2: ${empresa.diaPagamento2}');
          print('  TipoContratacaoId: ${empresa.tipoContratacaoId}');
          print('  BancoId: ${empresa.bancoId}');
          print('  Ativo: ${empresa.ativo}');
        }
      }

      setState(() {
        registeredEmpresas = empresas;
        isLoading = false;
      });
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao carregar empresas: $e');
      }

      setState(() {
        registeredEmpresas = [];
        isLoading = false;
      });

      _showErrorMessage('Erro ao carregar empresas: $e');
    }
  }

  // Adicionar verificação de tipo de contratação válido no método _addOrUpdateEmpresa
  void _addOrUpdateEmpresa() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isLoading = true; // Mostrar indicador de carregamento
      });

      try {
        // Converter valores para o formato correto
        double valor = double.tryParse(_valorController.text
                .replaceAll(RegExp(r'[^\d,.]'), '')
                .replaceAll(',', '.')) ??
            0.0;
        double? valorVA;

        if (_valorVAController.text.isNotEmpty) {
          valorVA = double.tryParse(_valorVAController.text
                  .replaceAll(RegExp(r'[^\d,.]'), '')
                  .replaceAll(',', '.')) ??
              0.0;
        }

        // Verificar se os dias de pagamento foram selecionados
        if (selectedDiaPagamento1 == null) {
          _showErrorMessage('Por favor, selecione o dia de pagamento 1');
          setState(() {
            isLoading = false;
          });
          return;
        }

        // Verificar se o tipo de contratação existe
        if (selectedTipoContratacaoId == null) {
          _showErrorMessage('Por favor, selecione o tipo de contratação');
          setState(() {
            isLoading = false;
          });
          return;
        }

        // Lista de IDs válidos conhecidos
        final validIds = [1, 3, 4];

        // Verificar se o tipo de contratação selecionado é válido
        if (!validIds.contains(selectedTipoContratacaoId)) {
          if (kDebugMode) {
            print(
                'Tipo de contratação com ID $selectedTipoContratacaoId não é válido.');
            print('IDs válidos: $validIds');
          }

          // Mapear para um ID válido
          int novoId;
          if (selectedTipoContratacaoId == 2) {
            novoId = 3; // Mapear ID 2 para ID 3 (PJ)
          } else {
            novoId = 1; // Valor padrão para outros casos
          }

          if (kDebugMode) {
            print(
                'Mapeando ID $selectedTipoContratacaoId para ID válido $novoId');
          }

          // Atualizar o ID selecionado
          selectedTipoContratacaoId = novoId;

          // Mostrar mensagem informativa
          _showErrorMessage(
              'Tipo de contratação ajustado automaticamente para um valor compatível');
        }

        if (kDebugMode) {
          print('Valores antes de criar/atualizar empresa:');
          print('  Nome: ${_nomeController.text}');
          print('  Cliente: ${_clienteController.text}');
          print('  Valor: $valor');
          print('  ValorVA: $valorVA');
          print('  TipoContratacaoId: $selectedTipoContratacaoId');
          print('  DiaPagamento1: $selectedDiaPagamento1');
          print('  DiaPagamento2: $selectedDiaPagamento2');
          print('  BancoId: $selectedBancoId');
          print('  Ativo: $ativo');
        }

        if (isEditing && editingEmpresaId != null) {
          // Atualizar empresa existente
          final empresaToUpdate = EmpresaModel(
            empresaId: editingEmpresaId,
            usuarioId: _usuarioId,
            nome: _nomeController.text,
            cliente: _clienteController.text,
            valor: valor,
            valorVA: valorVA,
            ativo: ativo,
            tipoContratacaoId: selectedTipoContratacaoId!,
            diaPagamento1: selectedDiaPagamento1!,
            diaPagamento2: selectedDiaPagamento2,
            bancoId: selectedBancoId,
          );

          if (kDebugMode) {
            print(
                'Atualizando empresa: ${json.encode(empresaToUpdate.toJson())}');
          }

          // Usar o serviço para atualizar a empresa
          final updatedEmpresa =
              await _empresaService.updateEmpresa(empresaToUpdate);

          if (kDebugMode) {
            print(
                'Empresa atualizada: ${updatedEmpresa.empresaId} - ${updatedEmpresa.nome}');
          }

          _showSuccessMessage('Empresa atualizada com sucesso!');

          // Forçar uma recarga completa das empresas
          await Future.delayed(Duration(
              milliseconds:
                  500)); // Pequeno atraso para garantir que a API processou a atualização
          await _loadEmpresas();

          _resetForm();
        } else {
          // Criar nova empresa
          final newEmpresa = EmpresaModel(
            usuarioId: _usuarioId,
            nome: _nomeController.text,
            cliente: _clienteController.text,
            valor: valor,
            valorVA: valorVA,
            ativo: ativo,
            tipoContratacaoId: selectedTipoContratacaoId!,
            diaPagamento1: selectedDiaPagamento1!,
            diaPagamento2: selectedDiaPagamento2,
            bancoId: selectedBancoId,
          );

          if (kDebugMode) {
            print('Criando empresa: ${json.encode(newEmpresa.toJson())}');
            print('TipoContratacaoId selecionado: $selectedTipoContratacaoId');
          }

          try {
            // Usar o serviço para criar a empresa
            final createdEmpresa =
                await _empresaService.createEmpresa(newEmpresa);

            if (kDebugMode) {
              print(
                  'Empresa criada: ${createdEmpresa.empresaId} - ${createdEmpresa.nome}');
            }

            _showSuccessMessage('Empresa cadastrada com sucesso!');

            // Forçar uma recarga completa das empresas
            await Future.delayed(Duration(
                milliseconds:
                    500)); // Pequeno atraso para garantir que a API processou a criação
            await _loadEmpresas();

            _resetForm();
          } catch (e) {
            if (kDebugMode) {
              print('Erro detalhado ao cadastrar empresa: $e');
            }

            String errorMessage = 'Erro ao cadastrar empresa';
            if (e.toString().contains('tipo de contratação')) {
              errorMessage =
                  'Erro com o tipo de contratação. Por favor, selecione outro tipo.';
            }

            _showErrorMessage(errorMessage);
            setState(() {
              isLoading = false;
            });
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('Erro ao ${isEditing ? 'atualizar' : 'cadastrar'} empresa: $e');
        }
        _showErrorMessage(
            'Erro ao ${isEditing ? 'atualizar' : 'cadastrar'} empresa: $e');
      } finally {
        setState(() {
          isLoading = false; // Esconder indicador de carregamento
        });
      }
    }
  }

  void _editEmpresa(EmpresaModel empresa) {
    if (kDebugMode) {
      print('Editando empresa:');
      print('  ID: ${empresa.empresaId}');
      print('  Nome: ${empresa.nome}');
      print('  Cliente: ${empresa.cliente}');
      print('  Valor: ${empresa.valor}');
      print('  ValorVA: ${empresa.valorVA}');
      print('  TipoContratacaoId: ${empresa.tipoContratacaoId}');
      print('  DiaPagamento1: ${empresa.diaPagamento1}');
      print('  DiaPagamento2: ${empresa.diaPagamento2}');
      print('  BancoId: ${empresa.bancoId}');
      print('  Ativo: ${empresa.ativo}');
    }

    // Garantir que os valores dos dias de pagamento sejam válidos
    int diaPagamento1 = empresa.diaPagamento1;
    if (diaPagamento1 < 1 || diaPagamento1 > 31) {
      diaPagamento1 = 1;
    }

    int? diaPagamento2 = empresa.diaPagamento2;
    if (diaPagamento2 != null && (diaPagamento2 < 1 || diaPagamento2 > 31)) {
      diaPagamento2 = null;
    }

    setState(() {
      isEditing = true;
      editingEmpresaId = empresa.empresaId;
      _nomeController.text = empresa.nome;
      _clienteController.text = empresa.cliente;
      _valorController.text = empresa.valor.toString();
      if (empresa.valorVA != null) {
        _valorVAController.text = empresa.valorVA.toString();
      } else {
        _valorVAController.clear();
      }
      selectedTipoContratacaoId = empresa.tipoContratacaoId;
      selectedBancoId = empresa.bancoId;
      selectedDiaPagamento1 = diaPagamento1;
      selectedDiaPagamento2 = diaPagamento2;
      ativo = empresa.ativo;
    });

    if (kDebugMode) {
      print('Valores definidos para edição:');
      print('  selectedTipoContratacaoId: $selectedTipoContratacaoId');
      print('  selectedDiaPagamento1: $selectedDiaPagamento1');
      print('  selectedDiaPagamento2: $selectedDiaPagamento2');
      print('  selectedBancoId: $selectedBancoId');
    }
  }

  void _deleteEmpresa(EmpresaModel empresa) async {
    try {
      // Usar o serviço para excluir a empresa
      await _empresaService.deleteEmpresa(empresa.empresaId!, _usuarioId);

      _showSuccessMessage('Empresa excluída com sucesso!');
      await _loadEmpresas();
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao excluir empresa: $e');
      }
      _showErrorMessage('Erro ao excluir empresa: $e');
    }
  }

  void _showDeleteConfirmation(EmpresaModel empresa) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF374151),
          title:
              Text('Confirmar exclusão', style: TextStyle(color: Colors.white)),
          content: Text(
            'Deseja realmente excluir a empresa ${empresa.nome}?',
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
                _deleteEmpresa(empresa);
              },
            ),
          ],
        );
      },
    );
  }

  // Gerar lista de dias para os dropdowns
  List<DropdownMenuItem<int>> _buildDiasDropdownItems() {
    return List.generate(31, (index) => index + 1)
        .map((dia) => DropdownMenuItem<int>(
              value: dia,
              child: Text('$dia', style: TextStyle(color: Colors.white)),
            ))
        .toList();
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _clienteController.dispose();
    _valorController.dispose();
    _valorVAController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Verificar se o tipo de contratação selecionado é CLT
    bool isCLT = false;
    if (selectedTipoContratacaoId != null) {
      final selectedTipo = tiposContratacao.firstWhere(
        (tipo) => tipo.id == selectedTipoContratacaoId,
        orElse: () => ContractType(id: 0, description: ''),
      );
      isCLT = selectedTipo.description.toUpperCase() == 'CLT';
    }

    return Scaffold(
      backgroundColor: Color(0xFF1F2937),
      appBar: AppBar(
        title: Text('Cadastro de Empresas'),
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
                              isEditing ? 'Editar Empresa' : 'Nova Empresa',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 16),

                            // Nome da Empresa
                            TextFormField(
                              controller: _nomeController,
                              decoration: InputDecoration(
                                labelText: 'Nome da Empresa',
                                labelStyle: TextStyle(color: Colors.white),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                              ),
                              style: TextStyle(color: Colors.white),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, informe o nome da empresa';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),

                            // Cliente
                            TextFormField(
                              controller: _clienteController,
                              decoration: InputDecoration(
                                labelText: 'Cliente',
                                labelStyle: TextStyle(color: Colors.white),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                              ),
                              style: TextStyle(color: Colors.white),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, informe o cliente';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),

                            // Tipo de Contratação
                            DropdownButtonFormField<int>(
                              decoration: InputDecoration(
                                labelText: 'Tipo de Contratação',
                                labelStyle: TextStyle(color: Colors.white),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                              ),
                              dropdownColor: Color(0xFF374151),
                              value: selectedTipoContratacaoId,
                              items: tiposContratacao.map((tipo) {
                                return DropdownMenuItem<int>(
                                  value: tipo.id,
                                  child: Text(tipo.description,
                                      style: TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (int? newValue) {
                                setState(() {
                                  selectedTipoContratacaoId = newValue;

                                  // Verificar se o novo tipo é CLT
                                  final selectedTipo =
                                      tiposContratacao.firstWhere(
                                    (tipo) => tipo.id == newValue,
                                    orElse: () =>
                                        ContractType(id: 0, description: ''),
                                  );

                                  bool newIsCLT =
                                      selectedTipo.description.toUpperCase() ==
                                          'CLT';

                                  // Se não for CLT, limpar o valor VA e o dia de pagamento 2
                                  if (!newIsCLT) {
                                    _valorVAController.clear();
                                    selectedDiaPagamento2 = null;
                                  }
                                });
                              },
                              style: TextStyle(color: Colors.white),
                              validator: (value) {
                                if (value == null) {
                                  return 'Por favor, selecione o tipo de contratação';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),

                            // Valor
                            TextFormField(
                              controller: _valorController,
                              decoration: InputDecoration(
                                labelText: 'Valor',
                                labelStyle: TextStyle(color: Colors.white),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                                prefixText: 'R\$ ',
                                prefixStyle: TextStyle(color: Colors.white),
                              ),
                              style: TextStyle(color: Colors.white),
                              keyboardType: TextInputType.numberWithOptions(
                                  decimal: true),
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Por favor, informe o valor';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),

                            // Valor VA (apenas se for CLT)
                            if (isCLT)
                              TextFormField(
                                controller: _valorVAController,
                                decoration: InputDecoration(
                                  labelText: 'Valor VA',
                                  labelStyle: TextStyle(color: Colors.white),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                  prefixText: 'R\$ ',
                                  prefixStyle: TextStyle(color: Colors.white),
                                ),
                                style: TextStyle(color: Colors.white),
                                keyboardType: TextInputType.numberWithOptions(
                                    decimal: true),
                              ),
                            if (isCLT) SizedBox(height: 16),

                            // Dia de Pagamento 1
                            DropdownButtonFormField<int>(
                              decoration: InputDecoration(
                                labelText: 'Dia de Pagamento 1',
                                labelStyle: TextStyle(color: Colors.white),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                              ),
                              dropdownColor: Color(0xFF374151),
                              value: selectedDiaPagamento1,
                              items: _buildDiasDropdownItems(),
                              onChanged: (int? newValue) {
                                setState(() {
                                  selectedDiaPagamento1 = newValue;
                                });
                              },
                              style: TextStyle(color: Colors.white),
                              validator: (value) {
                                if (value == null) {
                                  return 'Por favor, selecione o dia de pagamento';
                                }
                                return null;
                              },
                            ),
                            SizedBox(height: 16),

                            // Dia de Pagamento 2 (apenas se for CLT)
                            if (isCLT)
                              DropdownButtonFormField<int>(
                                decoration: InputDecoration(
                                  labelText: 'Dia de Pagamento 2',
                                  labelStyle: TextStyle(color: Colors.white),
                                  border: OutlineInputBorder(),
                                  enabledBorder: OutlineInputBorder(
                                    borderSide: BorderSide(color: Colors.white),
                                  ),
                                ),
                                dropdownColor: Color(0xFF374151),
                                value: selectedDiaPagamento2,
                                items: _buildDiasDropdownItems(),
                                onChanged: (int? newValue) {
                                  setState(() {
                                    selectedDiaPagamento2 = newValue;
                                  });
                                },
                                style: TextStyle(color: Colors.white),
                              ),
                            if (isCLT) SizedBox(height: 16),

                            // Banco
                            DropdownButtonFormField<int>(
                              decoration: InputDecoration(
                                labelText: 'Banco',
                                labelStyle: TextStyle(color: Colors.white),
                                border: OutlineInputBorder(),
                                enabledBorder: OutlineInputBorder(
                                  borderSide: BorderSide(color: Colors.white),
                                ),
                              ),
                              dropdownColor: Color(0xFF374151),
                              value: selectedBancoId,
                              items: bancos.map((banco) {
                                return DropdownMenuItem<int>(
                                  value: banco.bancoId,
                                  child: Text('${banco.codigo} - ${banco.nome}',
                                      style: TextStyle(color: Colors.white)),
                                );
                              }).toList(),
                              onChanged: (int? newValue) {
                                setState(() {
                                  selectedBancoId = newValue;
                                });
                              },
                              style: TextStyle(color: Colors.white),
                            ),
                            SizedBox(height: 16),

                            // Ativo
                            SwitchListTile(
                              title: Text('Ativo',
                                  style: TextStyle(color: Colors.white)),
                              value: ativo,
                              onChanged: (bool value) {
                                setState(() {
                                  ativo = value;
                                });
                              },
                              activeColor: Colors.blue,
                            ),
                            SizedBox(height: 16),

                            // Botões
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton(
                                  child: Text(
                                      isEditing ? 'Atualizar' : 'Cadastrar'),
                                  onPressed: _addOrUpdateEmpresa,
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
                    'Empresas Cadastradas',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16),
                  registeredEmpresas.isEmpty
                      ? Center(
                          child: Text(
                            'Nenhuma empresa cadastrada',
                            style: TextStyle(color: Colors.white70),
                          ),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          itemCount: registeredEmpresas.length,
                          itemBuilder: (context, index) {
                            final empresa = registeredEmpresas[index];

                            // Encontrar a descrição do tipo de contratação
                            String tipoContratacaoDesc = '';
                            final tipoContratacao = tiposContratacao.firstWhere(
                              (tipo) => tipo.id == empresa.tipoContratacaoId,
                              orElse: () =>
                                  ContractType(id: 0, description: ''),
                            );
                            if (tipoContratacao.id != 0) {
                              tipoContratacaoDesc = tipoContratacao.description;
                            } else if (empresa.tipoContratacaoDescricao !=
                                null) {
                              tipoContratacaoDesc =
                                  empresa.tipoContratacaoDescricao!;
                            }

                            return Card(
                              color: Color(0xFF374151),
                              child: ListTile(
                                title: Text(empresa.nome,
                                    style: TextStyle(color: Colors.white)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Cliente: ${empresa.cliente}',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    Text(
                                      'Tipo: $tipoContratacaoDesc',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    Text(
                                      'Valor: ${currencyFormat.format(empresa.valor)}',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                    Text(
                                      'Dia Pagamento: ${empresa.diaPagamento1}${empresa.diaPagamento2 != null ? ' e ${empresa.diaPagamento2}' : ''}',
                                      style: TextStyle(color: Colors.white70),
                                    ),
                                  ],
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      empresa.ativo
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: empresa.ativo
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                    SizedBox(width: 8),
                                    IconButton(
                                      icon:
                                          Icon(Icons.edit, color: Colors.white),
                                      onPressed: () => _editEmpresa(empresa),
                                    ),
                                    IconButton(
                                      icon: Icon(Icons.delete,
                                          color: Colors.white),
                                      onPressed: () =>
                                          _showDeleteConfirmation(empresa),
                                    ),
                                  ],
                                ),
                                isThreeLine: true,
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
