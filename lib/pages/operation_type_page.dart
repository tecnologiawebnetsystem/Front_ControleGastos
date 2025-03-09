import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:controle_gasto_pessoal/models/operation_type.dart';
import 'package:controle_gasto_pessoal/repositories/operation_type_repository.dart';
import 'package:controle_gasto_pessoal/services/api_service.dart';
import 'package:controle_gasto_pessoal/services/auth_service.dart';

// Add this at the top of the file, after the imports
// This is a workaround for the backend not providing IDs
// We'll store the operation types in memory with their mock IDs
Map<String, OperationType> _operationTypeCache = {};

class OperationTypePage extends StatefulWidget {
  @override
  State<OperationTypePage> createState() => _OperationTypePageState();
}

class _OperationTypePageState extends State<OperationTypePage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  int _selectedCoefficient = 1;

  List<OperationType> _operationTypes = [];
  List<OperationType> _filteredOperationTypes = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _errorMessage;

  // Tipo de operação sendo editado (null se estiver criando um novo)
  OperationType? _editingOperationType;

  // Cache para armazenar os tipos de operação com IDs simulados
  Map<String, OperationType> _operationTypeCache = {};

  // Repositório e serviços
  final OperationTypeRepository _repository =
      OperationTypeRepository(ApiService());
  final AuthService _authService = AuthService();

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();

    // Adicionar listener para o campo de pesquisa
    _searchController.addListener(_filterOperationTypes);
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

    // Carregar tipos de operação
    await _loadOperationTypes();
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

  // Carregar tipos de operação do servidor
  Future<void> _loadOperationTypes() async {
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
        print('Carregando tipos de operação com token: $token');
      }

      final response = await _repository.getAll();

      if (response['success'] == true) {
        setState(() {
          _operationTypes = (response['data'] as List<OperationType>?) ?? [];
          _filteredOperationTypes = _operationTypes;
          _isLoading = false;
        });

        // Clear the cache and rebuild it
        _operationTypeCache.clear();

        // Armazenar os tipos de operação no cache
        for (var type in _operationTypes) {
          if (type.id != null) {
            _operationTypeCache[type.description] = type;
            if (kDebugMode) {
              print(
                  'Adicionado ao cache: ${type.description} com ID ${type.id}');
            }
          }
        }

        if (kDebugMode) {
          print('Tipos de operação carregados: ${_operationTypes.length}');
          for (var type in _operationTypes) {
            print(
                'Tipo carregado: ID=${type.id}, Descrição=${type.description}, Coeficiente=${type.coefficient}');
          }
          print('Cache de tipos de operação: $_operationTypeCache');
        }
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? 'Erro ao carregar tipos de operação';
          _isLoading = false;
        });

        if (kDebugMode) {
          print('Erro ao carregar tipos de operação: ${response['message']}');
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
        _errorMessage = 'Erro ao carregar tipos de operação: $e';
        _isLoading = false;
      });

      if (kDebugMode) {
        print('Exceção ao carregar tipos de operação: $e');
      }
    }
  }

  // Salvar tipo de operação (criar ou atualizar)
  Future<void> _saveOperationType() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final operationType = OperationType(
        id: _editingOperationType?.id,
        description: _descriptionController.text.trim(),
        coefficient: _selectedCoefficient,
      );

      if (kDebugMode) {
        if (_editingOperationType != null) {
          print(
              'Atualizando tipo de operação com ID: ${_editingOperationType!.id}');
        } else {
          print('Criando novo tipo de operação');
        }
        print('Objeto OperationType: $operationType');
      }

      final response = _editingOperationType == null
          ? await _repository.create(operationType)
          : await _repository.update(
              _editingOperationType!.id.toString(), operationType);

      if (response['success'] == true) {
        // If this is a new item, add it to the cache with its real ID
        if (_editingOperationType == null &&
            response['data'] is OperationType) {
          final createdItem = response['data'] as OperationType;
          if (createdItem.id != null) {
            _operationTypeCache[createdItem.description] = createdItem;
            if (kDebugMode) {
              print(
                  'Adicionado ao cache: ${createdItem.description} com ID ${createdItem.id}');
            }
          }
        }

        // Limpar o formulário
        _resetForm();

        // Recarregar a lista de tipos de operação
        await _loadOperationTypes();

        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ??
                (_editingOperationType == null
                    ? 'Tipo de operação criado com sucesso!'
                    : 'Tipo de operação atualizado com sucesso!')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? 'Erro ao salvar tipo de operação';
          _isLoading = false;
        });

        if (kDebugMode) {
          print('Erro ao salvar tipo de operação: ${response['message']}');
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
        _errorMessage = 'Erro ao salvar tipo de operação: $e';
        _isLoading = false;
      });

      if (kDebugMode) {
        print('Exceção ao salvar tipo de operação: $e');
      }
    }
  }

  // Excluir tipo de operação
  Future<void> _deleteOperationType(OperationType operationType) async {
    // Check if the operation type has a valid ID
    if (operationType.id == null) {
      // Check if we have a cached version with an ID
      if (_operationTypeCache.containsKey(operationType.description)) {
        operationType = _operationTypeCache[operationType.description]!;
        if (kDebugMode) {
          print(
              'Usando versão em cache com ID: ${operationType.id} para exclusão');
        }
      } else {
        setState(() {
          _errorMessage = 'Não é possível excluir um tipo de operação sem ID';
        });

        if (kDebugMode) {
          print('Tentativa de excluir tipo de operação sem ID');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não é possível excluir um tipo de operação sem ID'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (kDebugMode) {
        print(
            'Iniciando exclusão do tipo de operação com ID: ${operationType.id}');
      }

      final response = await _repository.delete(operationType.id.toString());

      if (response['success'] == true) {
        // Recarregar a lista de tipos de operação
        await _loadOperationTypes();

        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ??
                'Tipo de operação excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? 'Erro ao excluir tipo de operação';
          _isLoading = false;
        });

        if (kDebugMode) {
          print('Erro ao excluir tipo de operação: ${response['message']}');
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
        _errorMessage = 'Erro ao excluir tipo de operação: $e';
        _isLoading = false;
      });

      if (kDebugMode) {
        print('Exceção ao excluir tipo de operação: $e');
      }
    }
  }

  // Editar tipo de operação
  void _editOperationType(OperationType operationType) {
    if (kDebugMode) {
      print(
          'Editando tipo de operação: ID=${operationType.id}, Descrição=${operationType.description}, Coeficiente=${operationType.coefficient}');
    }

    // Check if we have a cached version with an ID
    if (operationType.id == null &&
        _operationTypeCache.containsKey(operationType.description)) {
      operationType = _operationTypeCache[operationType.description]!;
      if (kDebugMode) {
        print('Usando versão em cache com ID: ${operationType.id}');
      }
    }

    // Make sure we have a valid ID
    if (operationType.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não é possível editar um tipo de operação sem ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _editingOperationType = operationType;
      _descriptionController.text = operationType.description;
      _selectedCoefficient = operationType.coefficient;
    });
  }

  // Resetar formulário
  void _resetForm() {
    setState(() {
      _editingOperationType = null;
      _descriptionController.clear();
      _selectedCoefficient = 1;
      _isLoading = false;
    });
  }

  // Filtrar tipos de operação com base no texto de pesquisa
  void _filterOperationTypes() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredOperationTypes = _operationTypes;
      } else {
        _filteredOperationTypes = _operationTypes.where((operationType) {
          return operationType.description.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  // Botão para tentar novamente
  Widget _buildRetryButton() {
    return ElevatedButton.icon(
      onPressed: _loadOperationTypes,
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
        title: Text('Tipos de Operação'),
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
            onPressed: _isLoading ? null : _loadOperationTypes,
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
                            hintText: 'Pesquisar tipos de operação...',
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
                                    _editingOperationType == null
                                        ? 'Novo Tipo de Operação'
                                        : 'Editar Tipo de Operação',
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
                                  DropdownButtonFormField<int>(
                                    decoration: InputDecoration(
                                      labelText: 'Coeficiente',
                                      labelStyle:
                                          TextStyle(color: Colors.white),
                                      border: OutlineInputBorder(),
                                      enabledBorder: OutlineInputBorder(
                                        borderSide:
                                            BorderSide(color: Colors.white),
                                      ),
                                    ),
                                    dropdownColor: Color(0xFF374151),
                                    value: _selectedCoefficient,
                                    items: [
                                      DropdownMenuItem(
                                        value: 1,
                                        child: Text('1',
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ),
                                      DropdownMenuItem(
                                        value: -1,
                                        child: Text('-1',
                                            style:
                                                TextStyle(color: Colors.white)),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _selectedCoefficient = value!;
                                      });
                                    },
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      if (_editingOperationType != null)
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
                                            : _saveOperationType,
                                        child: Text(
                                            _editingOperationType == null
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

                        // Lista de tipos de operação
                        Container(
                          height: 300, // Altura fixa para a lista
                          child: _isLoading && _filteredOperationTypes.isEmpty
                              ? Center(
                                  child: CircularProgressIndicator(),
                                )
                              : _filteredOperationTypes.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _operationTypes.isEmpty
                                                ? 'Nenhum tipo de operação encontrado'
                                                : 'Nenhum tipo de operação corresponde à pesquisa',
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
                                      itemCount: _filteredOperationTypes.length,
                                      itemBuilder: (context, index) {
                                        final operationType =
                                            _filteredOperationTypes[index];
                                        return Card(
                                          color: Color(0xFF1F2937),
                                          margin: EdgeInsets.only(bottom: 8),
                                          child: ListTile(
                                            title: Text(
                                              operationType.description,
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                            subtitle: Text(
                                              'Coeficiente: ${operationType.coefficient}',
                                              style: TextStyle(
                                                  color: Colors.white70),
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
                                                            _editOperationType(
                                                                operationType),
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
                                                                'Excluir Tipo de Operação',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                              content: Text(
                                                                'Tem certeza que deseja excluir o tipo de operação "${operationType.description}"?',
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
                                                                    _deleteOperationType(
                                                                        operationType);
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
