import 'package:flutter/foundation.dart';

class EmpresaModel {
  int? empresaId;
  int usuarioId;
  String nome;
  String cliente;
  double valor;
  double? valorVA;
  bool ativo;
  int tipoContratacaoId;
  String? tipoContratacaoDescricao;
  int diaPagamento1;
  int? diaPagamento2;
  int? bancoId;
  String? bancoNome;

  EmpresaModel({
    this.empresaId,
    required this.usuarioId,
    required this.nome,
    required this.cliente,
    required this.valor,
    this.valorVA,
    required this.ativo,
    required this.tipoContratacaoId,
    this.tipoContratacaoDescricao,
    required this.diaPagamento1,
    this.diaPagamento2,
    this.bancoId,
    this.bancoNome,
  });

  factory EmpresaModel.fromJson(Map<String, dynamic> json) {
    // Adicionar log para depuração
    if (kDebugMode) {
      print('Empresa.fromJson: Processando JSON: $json');
    }

    // Processar o campo 'ativo' que pode vir em diferentes formatos
    bool ativoValue = false;
    if (json['ativo'] != null) {
      if (json['ativo'] is bool) {
        ativoValue = json['ativo'];
      } else if (json['ativo'] is String) {
        ativoValue =
            json['ativo'].toLowerCase() == 'true' || json['ativo'] == '1';
      } else if (json['ativo'] is int) {
        ativoValue = json['ativo'] == 1;
      }
    }
    if (json['Ativo'] != null) {
      if (json['Ativo'] is bool) {
        ativoValue = json['Ativo'];
      } else if (json['Ativo'] is String) {
        ativoValue =
            json['Ativo'].toLowerCase() == 'true' || json['Ativo'] == '1';
      } else if (json['Ativo'] is int) {
        ativoValue = json['Ativo'] == 1;
      }
    }

    // Processar os campos de dia de pagamento com as novas opções de nomes
    int diaPagamento1 = 1;
    try {
      // Verificar todas as possíveis variações do nome do campo
      if (json['diaPagamento1'] != null) {
        diaPagamento1 = int.parse(json['diaPagamento1'].toString());
      } else if (json['DiaPagamento1'] != null) {
        diaPagamento1 = int.parse(json['DiaPagamento1'].toString());
      } else if (json['diaPagamento_1'] != null) {
        diaPagamento1 = int.parse(json['diaPagamento_1'].toString());
      } else if (json['DiaPagamento_1'] != null) {
        diaPagamento1 = int.parse(json['DiaPagamento_1'].toString());
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao converter diaPagamento1: $e');
      }
    }

    int? diaPagamento2;
    try {
      // Verificar todas as possíveis variações do nome do campo
      if (json['diaPagamento2'] != null &&
          json['diaPagamento2'].toString().isNotEmpty) {
        diaPagamento2 = int.parse(json['diaPagamento2'].toString());
      } else if (json['DiaPagamento2'] != null &&
          json['DiaPagamento2'].toString().isNotEmpty) {
        diaPagamento2 = int.parse(json['DiaPagamento2'].toString());
      } else if (json['diaPagamento_2'] != null &&
          json['diaPagamento_2'].toString().isNotEmpty) {
        diaPagamento2 = int.parse(json['diaPagamento_2'].toString());
      } else if (json['DiaPagamento_2'] != null &&
          json['DiaPagamento_2'].toString().isNotEmpty) {
        diaPagamento2 = int.parse(json['DiaPagamento_2'].toString());
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao converter diaPagamento2: $e');
      }
    }

    // Processar o tipo de contratação
    int tipoContratacaoId = 1; // Valor padrão (CLT)
    try {
      int? rawId = json['tipoContratacaoId'] ??
          json['TipoContratacaoId'] ??
          json['tipoContratacaoID'] ??
          json['TipoContratacaoID'];

      if (rawId != null) {
        // Garantir que o ID seja um dos valores válidos (1, 3, 4)
        if ([1, 3, 4].contains(rawId)) {
          tipoContratacaoId = rawId;
        } else {
          if (kDebugMode) {
            print('Tipo de contratação inválido: $rawId, usando padrão (1)');
          }
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Erro ao processar tipoContratacaoId: $e');
      }
    }

    if (kDebugMode) {
      print('Empresa.fromJson: Campo ativo processado: $ativoValue');
      print('Empresa.fromJson: DiaPagamento1 processado: $diaPagamento1');
      print('Empresa.fromJson: DiaPagamento2 processado: $diaPagamento2');
      print(
          'Empresa.fromJson: TipoContratacaoId processado: $tipoContratacaoId');
    }

    return EmpresaModel(
      empresaId: json['empresaId'] ??
          json['EmpresaId'] ??
          json['empresaid'] ??
          json['EmpresaID'],
      usuarioId: json['usuarioId'] ??
          json['UsuarioId'] ??
          json['usuarioid'] ??
          json['UsuarioID'] ??
          0,
      nome: json['nome'] ?? json['Nome'] ?? '',
      cliente: json['cliente'] ?? json['Cliente'] ?? '',
      valor: (json['valor'] ?? json['Valor'] ?? 0.0).toDouble(),
      valorVA: json['valorVA'] != null
          ? (json['valorVA']).toDouble()
          : json['ValorVA'] != null
              ? (json['ValorVA']).toDouble()
              : null,
      ativo: ativoValue,
      tipoContratacaoId: tipoContratacaoId,
      tipoContratacaoDescricao: json['tipoContratacaoDescricao'] ??
          json['TipoContratacaoDescricao'] ??
          '',
      diaPagamento1: diaPagamento1,
      diaPagamento2: diaPagamento2,
      bancoId: json['bancoId'] ??
          json['BancoId'] ??
          json['bancoID'] ??
          json['BancoID'],
      bancoNome: json['bancoNome'] ?? json['BancoNome'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    // Garantir que o tipo de contratação seja válido
    int validTipoContratacaoId = tipoContratacaoId;

    if (kDebugMode) {
      print('Empresa.toJson: Convertendo empresa para JSON');
      print('Empresa.toJson: TipoContratacaoId original: $tipoContratacaoId');
    }

    final Map<String, dynamic> data = {
      'UsuarioId': usuarioId,
      'Nome': nome,
      'Cliente': cliente,
      'Valor': valor,
      'Ativo': ativo,
      'TipoContratacaoId': validTipoContratacaoId,
      'DiaPagamento1': diaPagamento1,
    };

    // Adicionar o ID apenas se não for nulo
    if (empresaId != null) {
      data['EmpresaId'] = empresaId;
    }

    // Adicionar valorVA apenas se não for nulo
    if (valorVA != null) {
      data['ValorVA'] = valorVA;
    }

    // Adicionar diaPagamento2 apenas se não for nulo
    if (diaPagamento2 != null) {
      data['DiaPagamento2'] = diaPagamento2;
    }

    // Adicionar bancoId apenas se não for nulo
    if (bancoId != null) {
      data['BancoId'] = bancoId;
    }

    if (kDebugMode) {
      print('Empresa.toJson: Dados convertidos: $data');
    }

    return data;
  }
}
