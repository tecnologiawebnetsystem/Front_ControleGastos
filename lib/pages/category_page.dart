import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:controle_gasto_pessoal/models/expense_category.dart';
import 'package:controle_gasto_pessoal/repositories/category_repository.dart';
import 'package:controle_gasto_pessoal/services/api_service.dart';
import 'package:controle_gasto_pessoal/services/auth_service.dart';

class CategoryPage extends StatefulWidget {
  @override
  _CategoryPageState createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  int _selectedCoefficient = 1;

  List<ExpenseCategory> _categories = [];
  bool _isLoading = true;
  bool _isAdmin = false;
  String? _errorMessage;

  // Categoria sendo editada (null se estiver criando uma nova)
  ExpenseCategory? _editingCategory;

  // Repositório e serviços
  final CategoryRepository _repository = CategoryRepository(ApiService());
  final AuthService _authService = AuthService();

  final _searchController = TextEditingController();
  List<ExpenseCategory> _filteredCategories = [];

  @override
  void initState() {
    super.initState();
    _initializeData();

    // Adicionar listener para o campo de pesquisa
    _searchController.addListener(_filterCategories);
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

    // Carregar categorias
    await _loadCategories();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _searchController.dispose();
    super.dispose();
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

  // Carregar categorias do servidor
  Future<void> _loadCategories() async {
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
        print('Carregando categorias com token: $token');
      }

      final response = await _repository.getAll();

      if (response['success'] == true) {
        setState(() {
          _categories = (response['data'] as List<ExpenseCategory>?) ?? [];
          _isLoading = false;
        });

        _filteredCategories = _categories;

        if (kDebugMode) {
          print('Categorias carregadas: ${_categories.length}');
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Erro ao carregar categorias';
          _isLoading = false;
        });

        if (kDebugMode) {
          print('Erro ao carregar categorias: ${response['message']}');
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
        _errorMessage = 'Erro ao carregar categorias: $e';
        _isLoading = false;
      });

      if (kDebugMode) {
        print('Exceção ao carregar categorias: $e');
      }
    }
  }

  // Salvar categoria (criar ou atualizar)
  Future<void> _saveCategory() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final category = ExpenseCategory(
        id: _editingCategory?.id,
        name: _nameController.text.trim(),
        coefficient: _selectedCoefficient,
      );

      final response = _editingCategory == null
          ? await _repository.create(category)
          : await _repository.update(_editingCategory!.id.toString(), category);

      if (response['success'] == true) {
        // Limpar o formulário
        _resetForm();

        // Recarregar a lista de categorias
        await _loadCategories();

        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_editingCategory == null
                ? 'Categoria criada com sucesso!'
                : 'Categoria atualizada com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Erro ao salvar categoria';
          _isLoading = false;
        });

        if (kDebugMode) {
          print('Erro ao salvar categoria: ${response['message']}');
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
        _errorMessage = 'Erro ao salvar categoria: $e';
        _isLoading = false;
      });

      if (kDebugMode) {
        print('Exceção ao salvar categoria: $e');
      }
    }
  }

  // Excluir categoria
  Future<void> _deleteCategory(ExpenseCategory category) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _repository.delete(category.id.toString());

      if (response['success'] == true) {
        // Recarregar a lista de categorias
        await _loadCategories();

        // Mostrar mensagem de sucesso
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Categoria excluída com sucesso!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Erro ao excluir categoria';
          _isLoading = false;
        });

        if (kDebugMode) {
          print('Erro ao excluir categoria: ${response['message']}');
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
        _errorMessage = 'Erro ao excluir categoria: $e';
        _isLoading = false;
      });

      if (kDebugMode) {
        print('Exceção ao excluir categoria: $e');
      }
    }
  }

  // Editar categoria
  void _editCategory(ExpenseCategory category) {
    setState(() {
      _editingCategory = category;
      _nameController.text = category.name;
      _selectedCoefficient = category.coefficient;
    });
  }

  // Resetar formulário
  void _resetForm() {
    setState(() {
      _editingCategory = null;
      _nameController.clear();
      _selectedCoefficient = 1;
      _isLoading = false;
    });
  }

  // Botão para tentar novamente
  Widget _buildRetryButton() {
    return ElevatedButton.icon(
      onPressed: _loadCategories,
      icon: Icon(Icons.refresh),
      label: Text('Tentar Novamente'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
      ),
    );
  }

  // Filtrar categorias com base no texto de pesquisa
  void _filterCategories() {
    final query = _searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        _filteredCategories = _categories;
      } else {
        _filteredCategories = _categories.where((category) {
          return category.name.toLowerCase().contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1F2937),
      appBar: AppBar(
        title: Text('Categorias de Despesas'),
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
          // Botão de atualizar
          IconButton(
            icon: Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _isLoading ? null : _loadCategories,
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Card(
          color: Color(0xFF374151),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Campo de pesquisa
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Pesquisar categorias...',
                    hintStyle: TextStyle(color: Colors.white70),
                    prefixIcon: Icon(Icons.search, color: Colors.white70),
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
                            _editingCategory == null
                                ? 'Nova Categoria'
                                : 'Editar Categoria',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 16),
                          TextFormField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Nome da Categoria',
                              labelStyle: TextStyle(color: Colors.white),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                            ),
                            style: TextStyle(color: Colors.white),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Por favor, insira o nome da categoria';
                              }
                              return null;
                            },
                          ),
                          SizedBox(height: 16),
                          DropdownButtonFormField<int>(
                            decoration: InputDecoration(
                              labelText: 'Coeficiente',
                              labelStyle: TextStyle(color: Colors.white),
                              border: OutlineInputBorder(),
                              enabledBorder: OutlineInputBorder(
                                borderSide: BorderSide(color: Colors.white),
                              ),
                            ),
                            dropdownColor: Color(0xFF374151),
                            value: _selectedCoefficient,
                            items: [
                              DropdownMenuItem(
                                value: 1,
                                child: Text('1',
                                    style: TextStyle(color: Colors.white)),
                              ),
                              DropdownMenuItem(
                                value: -1,
                                child: Text('-1',
                                    style: TextStyle(color: Colors.white)),
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
                              if (_editingCategory != null)
                                TextButton(
                                  onPressed: _resetForm,
                                  child: Text('Cancelar'),
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: _isLoading ? null : _saveCategory,
                                child: Text(_editingCategory == null
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

                // Mensagem de erro
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.withOpacity(0.5)),
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

                if (_isAdmin) SizedBox(height: 16),

                // Lista de categorias
                Expanded(
                  child: _isLoading && _filteredCategories.isEmpty
                      ? Center(
                          child: CircularProgressIndicator(),
                        )
                      : _filteredCategories.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _categories.isEmpty
                                        ? 'Nenhuma categoria encontrada'
                                        : 'Nenhuma categoria corresponde à pesquisa',
                                    style: TextStyle(color: Colors.white),
                                  ),
                                  SizedBox(height: 16),
                                  if (_errorMessage != null)
                                    _buildRetryButton(),
                                ],
                              ),
                            )
                          : ListView.builder(
                              itemCount: _filteredCategories.length,
                              itemBuilder: (context, index) {
                                final category = _filteredCategories[index];
                                return Card(
                                  color: Color(0xFF1F2937),
                                  margin: EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(
                                      category.name,
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    trailing: _isAdmin
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.edit,
                                                    color: Colors.white),
                                                onPressed: () =>
                                                    _editCategory(category),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete,
                                                    color: Colors.white),
                                                onPressed: () {
                                                  // Mostrar diálogo de confirmação
                                                  showDialog(
                                                    context: context,
                                                    builder: (context) =>
                                                        AlertDialog(
                                                      backgroundColor:
                                                          Color(0xFF374151),
                                                      title: Text(
                                                        'Excluir Categoria',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white),
                                                      ),
                                                      content: Text(
                                                        'Tem certeza que deseja excluir a categoria "${category.name}"?',
                                                        style: TextStyle(
                                                            color:
                                                                Colors.white70),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          child:
                                                              Text('Cancelar'),
                                                          onPressed: () =>
                                                              Navigator.of(
                                                                      context)
                                                                  .pop(),
                                                        ),
                                                        ElevatedButton(
                                                          style: ElevatedButton
                                                              .styleFrom(
                                                            backgroundColor:
                                                                Colors.red,
                                                          ),
                                                          child:
                                                              Text('Excluir'),
                                                          onPressed: () {
                                                            Navigator.of(
                                                                    context)
                                                                .pop();
                                                            _deleteCategory(
                                                                category);
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
    );
  }
}
