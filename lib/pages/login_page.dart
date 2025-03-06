import 'package:flutter/material.dart';
import 'package:controle_gasto_pessoal/utils/auth_provider.dart';
import 'package:flutter/foundation.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = AuthProvider.of(context).authService;
      final response = await authService.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      // Adicionar logs para depuração
      if (kDebugMode) {
        print('Resposta de login: $response');
        print('Success: ${response.success}');
        print('Token: ${response.token}');
        print('Message: ${response.message}');
      }

      // Considerar o login bem-sucedido se temos um token, independentemente do campo success
      if (response.success ||
          (response.token != null &&
              response.message == 'Login bem-sucedido')) {
        // Navegação para a página principal com logs adicionais
        if (kDebugMode) {
          print('Login bem-sucedido, redirecionando para a página principal');
        }

        // Usar pushAndRemoveUntil para garantir que a página de login seja removida da pilha
        Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
      } else {
        if (kDebugMode) {
          print('Login falhou: ${response.message}');
        }
        setState(() {
          _errorMessage = response.message ??
              'Falha na autenticação. Verifique suas credenciais.';
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro durante o login: $e');
      }
      setState(() {
        _errorMessage =
            'Erro ao conectar ao servidor. Tente novamente mais tarde.';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Resto do código permanece o mesmo
    return Scaffold(
      backgroundColor: Color(0xFF1F2937),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo ou ícone
              Icon(
                Icons.account_balance_wallet,
                size: 80,
                color: Colors.blue,
              ),
              SizedBox(height: 32),
              // Título
              Text(
                'Controle Financeiro Pessoal',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48),
              // Formulário
              Card(
                color: Color(0xFF374151),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Login',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 24),
                        // Campo de e-mail
                        TextFormField(
                          controller: _emailController,
                          decoration: InputDecoration(
                            labelText: 'E-mail',
                            labelStyle: TextStyle(color: Colors.white70),
                            prefixIcon:
                                Icon(Icons.email, color: Colors.white70),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white30),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue),
                            ),
                          ),
                          style: TextStyle(color: Colors.white),
                          keyboardType: TextInputType.emailAddress,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira seu e-mail';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(value)) {
                              return 'Por favor, insira um e-mail válido';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 16),
                        // Campo de senha
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Senha',
                            labelStyle: TextStyle(color: Colors.white70),
                            prefixIcon: Icon(Icons.lock, color: Colors.white70),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                                color: Colors.white70,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscurePassword = !_obscurePassword;
                                });
                              },
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.white30),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.blue),
                            ),
                          ),
                          style: TextStyle(color: Colors.white),
                          obscureText: _obscurePassword,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira sua senha';
                            }
                            return null;
                          },
                        ),
                        SizedBox(height: 24),
                        // Mensagem de erro
                        if (_errorMessage != null)
                          Container(
                            padding: EdgeInsets.symmetric(
                                vertical: 8, horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: Colors.red.withOpacity(0.5)),
                            ),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(color: Colors.red[300]),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        if (_errorMessage != null) SizedBox(height: 16),
                        // Botão de login
                        ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                                  ),
                                )
                              : Text('Entrar'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            textStyle: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        // Botão de login de teste (apenas para desenvolvimento)
                        if (kDebugMode)
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: TextButton(
                              onPressed: () {
                                // Navegar diretamente para a página principal (para testes)
                                Navigator.of(context).pushReplacementNamed('/');
                              },
                              child: Text(
                                'Entrar sem autenticação (apenas para testes)',
                                style: TextStyle(color: Colors.blue[300]),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
