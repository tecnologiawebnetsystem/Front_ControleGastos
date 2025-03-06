class Usuario {
  int? id;
  String nome;
  String email;
  String senha;
  DateTime? dataCriacao;
  String? login;
  bool? adm;
  bool? ativo;

  Usuario({
    this.id,
    required this.nome,
    required this.email,
    required this.senha,
    this.dataCriacao,
    this.login,
    this.adm,
    this.ativo,
  });

  factory Usuario.fromJson(Map<String, dynamic> json) {
    return Usuario(
      id: json['id'] ?? json['usuarioid'] ?? json['UsuarioID'],
      nome: json['nome'] ?? json['Nome'] ?? '',
      email: json['email'] ?? json['Email'] ?? '',
      senha: json['senha'] ?? json['Senha'] ?? '',
      dataCriacao: json['dataCriacao'] != null
          ? DateTime.parse(json['dataCriacao'])
          : (json['DataCriacao'] != null
              ? DateTime.parse(json['DataCriacao'])
              : null),
      login: json['login'] ?? json['Login'],
      adm: json['adm'] ?? json['Adm'] ?? false,
      ativo: json['ativo'] ?? json['Ativo'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'email': email,
      // Não incluir senha no JSON por segurança
      'dataCriacao': dataCriacao?.toIso8601String(),
      'login': login,
      'adm': adm,
      'ativo': ativo,
    };
  }
}
