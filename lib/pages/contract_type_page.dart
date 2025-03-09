import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:controle_gasto_pessoal/models/contract_type.dart';
import 'package:controle_gasto_pessoal/repositories/contract_type_repository.dart';
import 'package:controle_gasto_pessoal/services/api_service.dart';
import 'package:controle_gasto_pessoal/services/auth_service.dart';

// Add this at the top of the file, after the imports
// This is a workaround for the backend not providing IDs
// We'll store the contract types in memory with their mock IDs
Map<String, ContractType> _contractTypeCache = {};

class ContractTypePage extends StatefulWidget {
  @override
  State<ContractTypePage> createState() => _ContractTypePageState();
}

class _ContractTypePageState extends State<ContractTypePage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  List<ContractType> _contractTypes = [];
  List<ContractType> _filteredContractTypes = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _errorMessage;

  // Tipo de contratação sendo editado (null se estiver criando um novo)
  ContractType? _editingContractType;

  // Cache para armazenar os tipos de contratação com IDs simulados
  Map<String, ContractType> _contractTypeCache = {};

  // Repositório e serviços
  final ContractTypeRepository _repository =
      ContractTypeRepository(ApiService());
  final AuthService _authService = AuthService();

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();

    // Adicionar listener para o campo de pesquisa
    _searchController.addListener(_filterContractTypes);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Inicializar dados de forma assíncrona
  Future<void> _initializeData() async {
    // Garantir que o AuthService esteja inicializado
    await _authService.ensureInitialized();

    // Verificar se o usuário está autenticado
    if (!_authService.isAuthenticated()) {
      if (kDebugMode) {
        print('Usuário não autenticado. Redirecionando para a tela de login.');
      }

      // Redirecionar para a tela de login
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return;
    }

    // Verificar status de administrador
    await _checkAdminStatus();

    // Carregar tipos de contratação
    await _loadContractTypes();
  }

  // Verificar se o usuário é administrador
  Future<void> _checkAdminStatus() async {
    try {
      final userData = await _authService.getUserData();
      if (userData != null) {
        setState(() {
          // Verificar diferentes possibilidades para o campo adm
          _isAdmin = userData['adm'] == true ||
              userData['adm'] == 1 ||
              userData['Adm'] == true ||
              userData['Adm'] == 1;
        });

        if (kDebugMode) {
          print('Status de administrador: $_isAdmin');
          print('Dados do usuário: $userData');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao verificar status de administrador: $e');
      }
    }
  }

  // Carregar tipos de contratação do servidor
  Future<void> _loadContractTypes() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Verificar se o token está disponível
      final token = _authService.getToken();
      if (token == null) {
        setState(() {
          _errorMessage = 'Não foi possível autenticar. Faça login novamente.';
          _isLoading = false;
        });

        if (kDebugMode) {
          print('Token não encontrado. Redirecionando para login.');
        }

        // Redirecionar para a tela de login
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/login');
        });
        return;
      }

      if (kDebugMode) {
        print('Carregando tipos de contratação com token: $token');
      }

      final response = await _repository.getAll();

      if (response['success'] == true) {
        setState(() {
          _contractTypes = (response['data'] as List<ContractType>?) ?? [];
          _filteredContractTypes = _contractTypes;
          _isLoading = false;
        });

        // Clear the cache and rebuild it
        _contractTypeCache.clear();

        // Armazenar os tipos de contratação no cache
        for (var type in _contractTypes) {
          if (type.id != null) {
            _contractTypeCache[type.description] = type;
            if (kDebugMode) {
              print(
                  'Adicionado ao cache: ${type.description} com ID ${type.id}');
            }
          }
        }

        if (kDebugMode) {
          print('Tipos de contratação carregados: ${_contractTypes.length}');
          for (var type in _contractTypes) {
            print(
                'Tipo carregado: ID=${type.id}, Descrição=${type.description}');
          }
          print('Cache de tipos de contratação: $_contractTypeCache');
        }
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? 'Erro ao carregar tipos de contratação';
          _isLoading = false;
        });

        if (kDebugMode) {
          print(
              'Erro ao carregar tipos de contratação: ${response['message']}');
        }

        // Se o erro for de autenticação, redirecionar para login
        if (response['message']?.toString().contains('Token') == true ||
            response['message']?.toString().contains('autenticação') == true ||
            response['message']?.toString().contains('autorização') == true) {
          // Fazer logout e redirecionar para login
          await _authService.logout();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao carregar tipos de contratação: $e';
        _isLoading = false;
      });

      if (kDebugMode) {
        print('Exceção ao carregar tipos de contratação: $e');
      }
    }
  }

  // Salvar tipo de contratação (criar ou atualizar)
  Future<void> _saveContractType() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final contractType = ContractType(
        id: _editingContractType?.id,
        description: _descriptionController.text.trim(),
      );

      if (kDebugMode) {
        if (_editingContractType != null) {
          print(
              'Atualizando tipo de contratação com ID: ${_editingContractType!.id}');
        } else {
          print('Criando novo tipo de contratação');
        }
        print('Objeto ContractType: $contractType');
      }

      final response = _editingContractType == null
          ? await _repository.create(contractType)
          : await _repository.update(
              _editingContractType!.id.toString(), contractType);

      if (response['success'] == true) {
        // If this is a new item, add it to the cache with its real ID
        if (_editingContractType == null && response['data'] is ContractType) {
          final createdItem = response['data'] as ContractType;
          if (createdItem.id != null) {
            _contractTypeCache[createdItem.description] = createdItem;
            if (kDebugMode) {
              print(
                  'Adicionado ao cache: ${createdItem.description} com ID ${createdItem.id}');
            }
          }
        }

        // Limpar o formulário
        _resetForm();

        // Recarregar a lista de tipos de contratação
        await _loadContractTypes();

        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ??
                (_editingContractType == null
                    ? 'Tipo de contratação criado com sucesso!'
                    : 'Tipo de contratação atualizado com sucesso!')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? 'Erro ao salvar tipo de contratação';
          _isLoading = false;
        });

        if (kDebugMode) {
          print('Erro ao salvar tipo de contratação: ${response['message']}');
        }

        // Se o erro for de autenticação, redirecionar para login
        if (response['message']?.toString().contains('Token') == true ||
            response['message']?.toString().contains('autenticação') == true ||
            response['message']?.toString().contains('autorização') == true) {
          // Fazer logout e redirecionar para login
          await _authService.logout();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao salvar tipo de contratação: $e';
        _isLoading = false;
      });

      if (kDebugMode) {
        print('Exceção ao salvar tipo de contratação: $e');
      }
    }
  }

  // Excluir tipo de contratação
  Future<void> _deleteContractType(ContractType contractType) async {
    // Check if the contract type has a valid ID
    if (contractType.id == null) {
      setState(() {
        _errorMessage = 'Não é possível excluir um tipo de contratação sem ID';
      });

      if (kDebugMode) {
        print('Tentativa de excluir tipo de contratação sem ID');
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não é possível excluir um tipo de contratação sem ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (kDebugMode) {
        print(
            'Iniciando exclusão do tipo de contratação com ID: ${contractType.id}');
      }

      final response = await _repository.delete(contractType.id.toString());

      if (response['success'] == true) {
        // Recarregar a lista de tipos de contratação
        await _loadContractTypes();

        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ??
                'Tipo de contratação excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? 'Erro ao excluir tipo de contratação';
          _isLoading = false;
        });

        if (kDebugMode) {
          print('Erro ao excluir tipo de contratação: ${response['message']}');
        }

        // Se o erro for de autenticação, redirecionar para login
        if (response['message']?.toString().contains('Token') == true ||
            response['message']?.toString().contains('autenticação') == true ||
            response['message']?.toString().contains('autorização') == true) {
          // Fazer logout e redirecionar para login
          await _authService.logout();

          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed('/login');
          });
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao excluir tipo de contratação: $e';
        _isLoading = false;
      });

      if (kDebugMode) {
        print('Exceção ao excluir tipo de contratação: $e');
      }
    }
  }

  // Editar tipo de contratação
  void _editContractType(ContractType contractType) {
    if (kDebugMode) {
      print(
          'Editando tipo de contratação: ID=${contractType.id}, Descrição=${contractType.description}');
    }

    // Check if we have a cached version with an ID
    if (contractType.id == null &&
        _contractTypeCache.containsKey(contractType.description)) {
      contractType = _contractTypeCache[contractType.description]!;
      if (kDebugMode) {
        print('Usando versão em cache com ID: ${contractType.id}');
      }
    }

    // Make sure we have a valid ID
    if (contractType.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não é possível editar um tipo de contratação sem ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _editingContractType = contractType;
      _descriptionController.text = contractType.description;
    });
  }

  // Resetar formulário
  void _resetForm() {
    setState(() {
      _editingContractType = null;
      _descriptionController.clear();
      _isLoading = false;
    });
  }

  // Filtrar tipos de contratação com base no texto de pesquisa
  void _filterContractTypes() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredContractTypes = _contractTypes;
      } else {
        _filteredContractTypes = _contractTypes.where((contractType) {
          return contractType.description.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  // Botão para tentar novamente
  Widget _buildRetryButton() {
    return ElevatedButton.icon(
      onPressed: _loadContractTypes,
      icon: Icon(Icons.refresh),
      label: Text('Tentar Novamente'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1F2937),
      appBar: AppBar(
        title: Text('Tipos de Contratação'),
        backgroundColor: Color(0xFF111827),
        actions: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _isLoading ? null : _loadContractTypes,
          ),
        ],
      ),
      // Usar LayoutBuilder para ter mais controle sobre o layout
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight,
              ),
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Card(
                  color: Color(0xFF374151),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Campo de pesquisa
                        TextField(
                          controller: _searchController,
                          decoration: InputDecoration(
                            hintText: 'Pesquisar tipos de contratação...',
                            hintStyle: TextStyle(color: Colors.white70),
                            prefixIcon:
                                Icon(Icons.search, color: Colors.white70),
                            filled: true,
                            fillColor: Color(0xFF1F2937),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 12),
                          ),
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 16),

                        // Formulário (apenas para administradores)
                        if (_isAdmin)
                          Container(
                            decoration: BoxDecoration(
                              color: Color(0xFF1F2937),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            padding: EdgeInsets.all(16),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    _editingContractType == null
                                        ? 'Novo Tipo de Contratação'
                                        : 'Editar Tipo de Contratação',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 16),
                                  TextFormField(
                                    controller: _descriptionController,
                                    decoration: InputDecoration(
                                      labelText: 'Descrição',
                                      labelStyle:
                                          TextStyle(color: Colors.white),
                                      border: OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.white),
                                      ),
                                    ),
                                    style: TextStyle(color: Colors.white),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Por favor, insira a descrição';
                                      }
                                      return null;
                                    },
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (_editingContractType != null)
                                        TextButton(
                                          onPressed: _resetForm,
                                          child: Text('Cancelar'),
                                          style: TextButton.styleFrom(
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      SizedBox(width: 8),
                                      ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _saveContractType,
                                        child: Text(_editingContractType == null
                                            ? 'Adicionar'
                                            : 'Atualizar'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blue,
                                          disabledBackgroundColor:
                                              Colors.blue.withOpacity(0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                        if (_isAdmin) SizedBox(height: 16),

                        // Mensagem de erro
                        if (_errorMessage != null)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                    color: Colors.red.withOpacity(0.5)),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    _errorMessage!,
                                    style: TextStyle(color: Colors.red[300]),
                                  ),
                                  SizedBox(height: 8),
                                  _buildRetryButton(),
                                ],
                              ),
                            ),
                          ),

                        // Lista de tipos de contratação
                        Container(
                          height: 300, // Altura fixa para a lista
                          child: _isLoading && _filteredContractTypes.isEmpty
                              ? Center(
                                  child: CircularProgressIndicator(),
                                )
                              : _filteredContractTypes.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _contractTypes.isEmpty
                                                ? 'Nenhum tipo de contratação encontrado'
                                                : 'Nenhum tipo de contratação corresponde à pesquisa',
                                            style:
                                                TextStyle(color: Colors.white),
                                          ),
                                          if (_errorMessage != null)
                                            SizedBox(height: 16),
                                          if (_errorMessage != null)
                                            _buildRetryButton(),
                                        ],
                                      ),
                                    )
                                  : ListView.builder(
                                      itemCount: _filteredContractTypes.length,
                                      itemBuilder: (context, index) {
                                        final contractType =
                                            _filteredContractTypes[index];
                                        return Card(
                                          color: Color(0xFF1F2937),
                                          margin: EdgeInsets.only(bottom: 8),
                                          child: ListTile(
                                            title: Text(
                                              contractType.description,
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            trailing: _isAdmin
                                                ? Row(
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      IconButton(
                                                        icon: Icon(Icons.edit,
                                                            color:
                                                                Colors.white),
                                                        onPressed: () =>
                                                            _editContractType(
                                                                contractType),
                                                      ),
                                                      IconButton(
                                                        icon: Icon(Icons.delete,
                                                            color:
                                                                Colors.white),
                                                        onPressed: () {
                                                          showDialog(
                                                            context: context,
                                                            builder:
                                                                (context) =>
                                                                    AlertDialog(
                                                              backgroundColor:
                                                                  Color(
                                                                      0xFF374151),
                                                              title: Text(
                                                                'Excluir Tipo de Contratação',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                              content: Text(
                                                                'Tem certeza que deseja excluir o tipo de contratação "${contractType.description}"?',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white70),
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  child: Text(
                                                                      'Cancelar'),
                                                                  onPressed: () =>
                                                                      Navigator.of(
                                                                              context)
                                                                          .pop(),
                                                                ),
                                                                ElevatedButton(
                                                                  style: ElevatedButton
                                                                      .styleFrom(
                                                                    backgroundColor:
                                                                        Colors
                                                                            .red,
                                                                  ),
                                                                  child: Text(
                                                                      'Excluir'),
                                                                  onPressed:
                                                                      () {
                                                                    Navigator.of(
                                                                            context)
                                                                        .pop();
                                                                    _deleteContractType(
                                                                        contractType);
                                                                  },
                                                                ),
                                                              ],
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ],
                                                  )
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
