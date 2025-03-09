import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:controle_gasto_pessoal/models/payment_status.dart';
import 'package:controle_gasto_pessoal/repositories/payment_status_repository.dart';
import 'package:controle_gasto_pessoal/services/api_service.dart';
import 'package:controle_gasto_pessoal/services/auth_service.dart';

// Add this at the top of the file, after the imports
// This is a workaround for the backend not providing IDs
// We'll store the payment statuses in memory with their mock IDs
Map<String, PaymentStatus> _paymentStatusCache = {};

class PaymentStatusPage extends StatefulWidget {
  @override
  State<PaymentStatusPage> createState() => _PaymentStatusPageState();
}

class _PaymentStatusPageState extends State<PaymentStatusPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();

  List<PaymentStatus> _paymentStatuses = [];
  List<PaymentStatus> _filteredPaymentStatuses = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _errorMessage;

  // Status de pagamento sendo editado (null se estiver criando um novo)
  PaymentStatus? _editingPaymentStatus;

  // Cache para armazenar os status de pagamento com IDs simulados
  Map<String, PaymentStatus> _paymentStatusCache = {};

  // Repositório e serviços
  final PaymentStatusRepository _repository =
      PaymentStatusRepository(ApiService());
  final AuthService _authService = AuthService();

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeData();

    // Adicionar listener para o campo de pesquisa
    _searchController.addListener(_filterPaymentStatuses);
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

    // Carregar status de pagamento
    await _loadPaymentStatuses();
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

  // Carregar status de pagamento do servidor
  Future<void> _loadPaymentStatuses() async {
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
        print('Carregando status de pagamento com token: $token');
      }

      final response = await _repository.getAll();

      if (response['success'] == true) {
        setState(() {
          _paymentStatuses = (response['data'] as List<PaymentStatus>?) ?? [];
          _filteredPaymentStatuses = _paymentStatuses;
          _isLoading = false;
        });

        // Clear the cache and rebuild it
        _paymentStatusCache.clear();

        // Armazenar os status de pagamento no cache
        for (var status in _paymentStatuses) {
          if (status.id != null) {
            _paymentStatusCache[status.description] = status;
            if (kDebugMode) {
              print(
                  'Adicionado ao cache: ${status.description} com ID ${status.id}');
            }
          }
        }

        if (kDebugMode) {
          print('Status de pagamento carregados: ${_paymentStatuses.length}');
          for (var status in _paymentStatuses) {
            print(
                'Status carregado: ID=${status.id}, Descrição=${status.description}');
          }
          print('Cache de status de pagamento: $_paymentStatusCache');
        }
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? 'Erro ao carregar status de pagamento';
          _isLoading = false;
        });

        if (kDebugMode) {
          print('Erro ao carregar status de pagamento: ${response['message']}');
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
        _errorMessage = 'Erro ao carregar status de pagamento: $e';
        _isLoading = false;
      });

      if (kDebugMode) {
        print('Exceção ao carregar status de pagamento: $e');
      }
    }
  }

  // Salvar status de pagamento (criar ou atualizar)
  Future<void> _savePaymentStatus() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final paymentStatus = PaymentStatus(
        id: _editingPaymentStatus?.id,
        description: _descriptionController.text.trim(),
      );

      if (kDebugMode) {
        if (_editingPaymentStatus != null) {
          print(
              'Atualizando status de pagamento com ID: ${_editingPaymentStatus!.id}');
        } else {
          print('Criando novo status de pagamento');
        }
        print('Objeto PaymentStatus: $paymentStatus');
      }

      final response = _editingPaymentStatus == null
          ? await _repository.create(paymentStatus)
          : await _repository.update(
              _editingPaymentStatus!.id.toString(), paymentStatus);

      if (response['success'] == true) {
        // If this is a new item, add it to the cache with its real ID
        if (_editingPaymentStatus == null &&
            response['data'] is PaymentStatus) {
          final createdItem = response['data'] as PaymentStatus;
          if (createdItem.id != null) {
            _paymentStatusCache[createdItem.description] = createdItem;
            if (kDebugMode) {
              print(
                  'Adicionado ao cache: ${createdItem.description} com ID ${createdItem.id}');
            }
          }
        }

        // Limpar o formulário
        _resetForm();

        // Recarregar a lista de status de pagamento
        await _loadPaymentStatuses();

        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ??
                (_editingPaymentStatus == null
                    ? 'Status de pagamento criado com sucesso!'
                    : 'Status de pagamento atualizado com sucesso!')),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? 'Erro ao salvar status de pagamento';
          _isLoading = false;
        });

        if (kDebugMode) {
          print('Erro ao salvar status de pagamento: ${response['message']}');
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
        _errorMessage = 'Erro ao salvar status de pagamento: $e';
        _isLoading = false;
      });

      if (kDebugMode) {
        print('Exceção ao salvar status de pagamento: $e');
      }
    }
  }

  // Excluir status de pagamento
  Future<void> _deletePaymentStatus(PaymentStatus paymentStatus) async {
    // Check if the payment status has a valid ID
    if (paymentStatus.id == null) {
      // Check if we have a cached version with an ID
      if (_paymentStatusCache.containsKey(paymentStatus.description)) {
        paymentStatus = _paymentStatusCache[paymentStatus.description]!;
        if (kDebugMode) {
          print(
              'Usando versão em cache com ID: ${paymentStatus.id} para exclusão');
        }
      } else {
        setState(() {
          _errorMessage =
              'Não é possível excluir um status de pagamento sem ID';
        });

        if (kDebugMode) {
          print('Tentativa de excluir status de pagamento sem ID');
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('Não é possível excluir um status de pagamento sem ID'),
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
            'Iniciando exclusão do status de pagamento com ID: ${paymentStatus.id}');
      }

      final response = await _repository.delete(paymentStatus.id.toString());

      if (response['success'] == true) {
        // Recarregar a lista de status de pagamento
        await _loadPaymentStatuses();

        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ??
                'Status de pagamento excluído com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage =
              response['message'] ?? 'Erro ao excluir status de pagamento';
          _isLoading = false;
        });

        if (kDebugMode) {
          print('Erro ao excluir status de pagamento: ${response['message']}');
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
        _errorMessage = 'Erro ao excluir status de pagamento: $e';
        _isLoading = false;
      });

      if (kDebugMode) {
        print('Exceção ao excluir status de pagamento: $e');
      }
    }
  }

  // Editar status de pagamento
  void _editPaymentStatus(PaymentStatus paymentStatus) {
    if (kDebugMode) {
      print(
          'Editando status de pagamento: ID=${paymentStatus.id}, Descrição=${paymentStatus.description}');
    }

    // Check if we have a cached version with an ID
    if (paymentStatus.id == null &&
        _paymentStatusCache.containsKey(paymentStatus.description)) {
      paymentStatus = _paymentStatusCache[paymentStatus.description]!;
      if (kDebugMode) {
        print('Usando versão em cache com ID: ${paymentStatus.id}');
      }
    }

    // Make sure we have a valid ID
    if (paymentStatus.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não é possível editar um status de pagamento sem ID'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _editingPaymentStatus = paymentStatus;
      _descriptionController.text = paymentStatus.description;
    });
  }

  // Resetar formulário
  void _resetForm() {
    setState(() {
      _editingPaymentStatus = null;
      _descriptionController.clear();
      _isLoading = false;
    });
  }

  // Filtrar status de pagamento com base no texto de pesquisa
  void _filterPaymentStatuses() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredPaymentStatuses = _paymentStatuses;
      } else {
        _filteredPaymentStatuses = _paymentStatuses.where((paymentStatus) {
          return paymentStatus.description.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  // Botão para tentar novamente
  Widget _buildRetryButton() {
    return ElevatedButton.icon(
      onPressed: _loadPaymentStatuses,
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
        title: Text('Status de Pagamento'),
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
            onPressed: _isLoading ? null : _loadPaymentStatuses,
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
                            hintText: 'Pesquisar status de pagamento...',
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
                                    _editingPaymentStatus == null
                                        ? 'Novo Status de Pagamento'
                                        : 'Editar Status de Pagamento',
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
                                      if (_editingPaymentStatus != null)
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
                                            : _savePaymentStatus,
                                        child: Text(
                                            _editingPaymentStatus == null
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

                        // Lista de status de pagamento
                        Container(
                          height: 300, // Altura fixa para a lista
                          child: _isLoading && _filteredPaymentStatuses.isEmpty
                              ? Center(
                                  child: CircularProgressIndicator(),
                                )
                              : _filteredPaymentStatuses.isEmpty
                                  ? Center(
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            _paymentStatuses.isEmpty
                                                ? 'Nenhum status de pagamento encontrado'
                                                : 'Nenhum status de pagamento corresponde à pesquisa',
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
                                      itemCount:
                                          _filteredPaymentStatuses.length,
                                      itemBuilder: (context, index) {
                                        final paymentStatus =
                                            _filteredPaymentStatuses[index];
                                        return Card(
                                          color: Color(0xFF1F2937),
                                          margin: EdgeInsets.only(bottom: 8),
                                          child: ListTile(
                                            title: Text(
                                              paymentStatus.description,
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
                                                            _editPaymentStatus(
                                                                paymentStatus),
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
                                                                'Excluir Status de Pagamento',
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .white),
                                                              ),
                                                              content: Text(
                                                                'Tem certeza que deseja excluir o status de pagamento "${paymentStatus.description}"?',
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
                                                                    _deletePaymentStatus(
                                                                        paymentStatus);
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
