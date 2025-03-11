class AuthRequest {
  final String email;
  final String password; // Alterado de "senha" para "password"

  AuthRequest({
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'password': password, // Alterado de "senha" para "password"
    };
  }
}

class AuthResponse {
  final bool success;
  final String? message;
  final String? token;
  final Map<String, dynamic>? userData;

  AuthResponse({
    required this.success,
    this.message,
    this.token,
    this.userData,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Tentar extrair o token de diferentes locais possíveis na resposta
    String? token = json['token'];
    if (token == null && json['data'] != null) {
      token = json['data']['token'];
    }

    // Tentar extrair os dados do usuário de diferentes locais possíveis na resposta
    Map<String, dynamic>? userData;
    if (json['user'] != null) {
      userData = Map<String, dynamic>.from(json['user']);
    } else if (json['data'] != null && json['data']['user'] != null) {
      userData = Map<String, dynamic>.from(json['data']['user']);
    } else if (json['data'] != null && json['data'] is Map) {
      userData = Map<String, dynamic>.from(json['data']);
    }

    return AuthResponse(
      success: json['success'] ?? false,
      message: json['message'],
      token: token,
      userData: userData,
    );
  }
}
