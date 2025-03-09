class BancoModel {
  int? bancoId;
  int usuarioId;
  String nome;
  String codigo;
  String agencia;
  String conta;
  String pix;

  BancoModel({
    this.bancoId,
    required this.usuarioId,
    required this.nome,
    required this.codigo,
    required this.agencia,
    required this.conta,
    required this.pix,
  });

  factory BancoModel.fromJson(Map<String, dynamic> json) {
    return BancoModel(
      bancoId: json['bancoId'] ??
          json['BancoId'] ??
          json['bancoid'] ??
          json['BancoID'],
      usuarioId: json['usuarioId'] ??
          json['UsuarioId'] ??
          json['usuarioid'] ??
          json['UsuarioID'],
      nome: json['nome'] ?? json['Nome'] ?? '',
      codigo: json['codigo'] ?? json['Codigo'] ?? '',
      agencia: json['agencia'] ?? json['Agencia'] ?? '',
      conta: json['conta'] ?? json['Conta'] ?? '',
      pix: json['pix'] ?? json['Pix'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bancoId': bancoId,
      'usuarioId': usuarioId,
      'nome': nome,
      'codigo': codigo,
      'agencia': agencia,
      'conta': conta,
      'pix': pix,
    };
  }
}
