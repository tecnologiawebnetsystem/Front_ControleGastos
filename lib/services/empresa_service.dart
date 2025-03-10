import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:controle_gasto_pessoal/models/empresa_model.dart';
import 'package:controle_gasto_pessoal/models/contract_type.dart';
import 'package:controle_gasto_pessoal/models/banco_model.dart';
import 'package:controle_gasto_pessoal/config/environment.dart';
import 'package:flutter/foundation.dart';

class EmpresaService {
  final String token;

  EmpresaService({required this.token});

  // Obter a URL base da API
  String get baseUrl => AppConfig.apiBaseUrl;

  // Método auxiliar para construir URLs de API corretamente
  String _buildEndpointUrl(String endpoint) {
    // Verificar se o baseUrl já termina com "/api"
    if (baseUrl.endsWith('/api')) {
      // Se já termina com "/api", não adicionar novamente
      return '$baseUrl/$endpoint';
    } else {
      // Se não termina com "/api", adicionar
      return '$baseUrl/api/$endpoint';
    }
  }

  // Obter todas as empresas do usuário
  Future<List<EmpresaModel>> getEmpresas(int usuarioId) async {
    if (kDebugMode) {
      print('EmpresaService: Buscando empresas para o usuário ID: $usuarioId');
      print('EmpresaService: URL da API: ${AppConfig.apiBaseUrl}');
    }

    try {
      // Tentar com diferentes endpoints
      final endpoints = [
        _buildEndpointUrl('empresas/usuario/$usuarioId'),
        _buildEndpointUrl('empresas'),
      ];

      List<EmpresaModel> empresas = [];
      bool success = false;

      for (var endpoint in endpoints) {
        if (kDebugMode) {
          print('EmpresaService: Tentando endpoint: $endpoint');
        }

        try {
          final response = await http.get(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (kDebugMode) {
            print(
                'EmpresaService: Status da resposta para $endpoint: ${response.statusCode}');
            print(
                'EmpresaService: Corpo da resposta para $endpoint: ${response.body.substring(0, min(100, response.body.length))}...');
          }

          if (response.statusCode == 200) {
            final List<dynamic> data = json.decode(response.body);

            // Se o endpoint não for específico para o usuário, filtramos aqui
            if (endpoint.contains('/usuario/')) {
              empresas =
                  data.map((json) => EmpresaModel.fromJson(json)).toList();
            } else {
              empresas = data
                  .map((json) => EmpresaModel.fromJson(json))
                  .where((empresa) => empresa.usuarioId == usuarioId)
                  .toList();
            }

            success = true;
            if (kDebugMode) {
              print('EmpresaService: Sucesso com endpoint: $endpoint');
              print('EmpresaService: Empresas encontradas: ${empresas.length}');
              for (var empresa in empresas) {
                print(
                    'EmpresaService: Empresa: ${empresa.empresaId} - ${empresa.nome} - DiaPagamento1: ${empresa.diaPagamento1}, DiaPagamento2: ${empresa.diaPagamento2}');
              }
            }
            break;
          }
        } catch (e) {
          if (kDebugMode) {
            print('EmpresaService: Erro ao tentar $endpoint: $e');
          }
        }
      }

      if (success) {
        return empresas;
      } else {
        if (kDebugMode) {
          print(
              'EmpresaService: Nenhum endpoint funcionou. Retornando lista vazia.');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('EmpresaService: Exceção ao buscar empresas: $e');
      }
      return [];
    }
  }

  // Criar uma nova empresa
  Future<EmpresaModel> createEmpresa(EmpresaModel empresa) async {
    if (kDebugMode) {
      print('EmpresaService: Criando empresa');
      print('EmpresaService: Dados: ${json.encode(empresa.toJson())}');
    }

    // Garantir que o tipo de contratação seja válido
    if (empresa.tipoContratacaoId == null || empresa.tipoContratacaoId <= 0) {
      if (kDebugMode) {
        print(
            'EmpresaService: Tipo de contratação inválido ou nulo: ${empresa.tipoContratacaoId}. Usando valor padrão 1 (CLT)');
      }
      empresa = EmpresaModel(
        empresaId: empresa.empresaId,
        usuarioId: empresa.usuarioId,
        nome: empresa.nome,
        cliente: empresa.cliente,
        valor: empresa.valor,
        valorVA: empresa.valorVA,
        ativo: empresa.ativo,
        tipoContratacaoId: 1, // Forçar para um valor válido (CLT)
        tipoContratacaoDescricao: empresa.tipoContratacaoDescricao,
        diaPagamento1: empresa.diaPagamento1,
        diaPagamento2: empresa.diaPagamento2,
        bancoId: empresa.bancoId,
        bancoNome: empresa.bancoNome,
      );
    }

    try {
      // Tentar com diferentes endpoints
      final endpoints = [
        _buildEndpointUrl('empresas'),
        '$baseUrl/empresas', // Tentar sem o /api
        '${baseUrl}/api/empresas', // Tentar com /api explícito
        _buildEndpointUrl('empresa'), // Tentar no singular
      ];

      String? lastErrorMessage;
      int? lastStatusCode;
      String? lastResponseBody;

      for (var endpoint in endpoints) {
        if (kDebugMode) {
          print('EmpresaService: Tentando endpoint: $endpoint');
        }

        try {
          final Map<String, dynamic> empresaJson = empresa.toJson();
          final String jsonBody = json.encode(empresaJson);

          if (kDebugMode) {
            print('EmpresaService: Enviando JSON: $jsonBody');
          }

          final response = await http.post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: jsonBody,
          );

          lastStatusCode = response.statusCode;
          lastResponseBody = response.body;

          if (kDebugMode) {
            print(
                'EmpresaService: Status da resposta para $endpoint: ${response.statusCode}');
            print(
                'EmpresaService: Corpo da resposta para $endpoint: ${response.body}');
          }

          if (response.statusCode == 201 || response.statusCode == 200) {
            if (kDebugMode) {
              print('EmpresaService: Sucesso com endpoint: $endpoint');
            }

            // Verificar se a resposta tem um corpo válido
            if (response.body.isNotEmpty) {
              try {
                return EmpresaModel.fromJson(json.decode(response.body));
              } catch (e) {
                if (kDebugMode) {
                  print(
                      'EmpresaService: Erro ao converter resposta para EmpresaModel: $e');
                  print('EmpresaService: Retornando o objeto original');
                }
                // Se não conseguir converter, retornar o objeto original
                return empresa;
              }
            } else {
              // Se a resposta estiver vazia, retornar o objeto original
              if (kDebugMode) {
                print(
                    'EmpresaService: Resposta vazia, retornando o objeto original');
              }
              return empresa;
            }
          } else if (response.statusCode == 400) {
            // Tentar entender o erro
            try {
              final errorData = json.decode(response.body);
              lastErrorMessage =
                  errorData['message'] ?? 'Erro 400 sem mensagem específica';

              if (kDebugMode) {
                print('EmpresaService: Erro 400 detalhado: $errorData');
              }

              // Se o erro for relacionado ao tipo de contratação, tentar com outro valor
              if (errorData['message']
                      ?.toString()
                      .contains('tipo de contratação') ==
                  true) {
                if (kDebugMode) {
                  print(
                      'EmpresaService: Tentando com outro tipo de contratação...');
                }

                // Tentar com outro tipo de contratação
                final alternativeId = empresa.tipoContratacaoId == 1 ? 3 : 1;

                final alternativeEmpresa = EmpresaModel(
                  empresaId: empresa.empresaId,
                  usuarioId: empresa.usuarioId,
                  nome: empresa.nome,
                  cliente: empresa.cliente,
                  valor: empresa.valor,
                  valorVA: empresa.valorVA,
                  ativo: empresa.ativo,
                  tipoContratacaoId: alternativeId,
                  tipoContratacaoDescricao: empresa.tipoContratacaoDescricao,
                  diaPagamento1: empresa.diaPagamento1,
                  diaPagamento2: empresa.diaPagamento2,
                  bancoId: empresa.bancoId,
                  bancoNome: empresa.bancoNome,
                );

                final alternativeJson = alternativeEmpresa.toJson();
                final alternativeJsonBody = json.encode(alternativeJson);

                if (kDebugMode) {
                  print(
                      'EmpresaService: Tentando com JSON alternativo: $alternativeJsonBody');
                }

                final alternativeResponse = await http.post(
                  Uri.parse(endpoint),
                  headers: {
                    'Content-Type': 'application/json',
                    'Authorization': 'Bearer $token',
                  },
                  body: alternativeJsonBody,
                );

                if (alternativeResponse.statusCode == 201 ||
                    alternativeResponse.statusCode == 200) {
                  if (kDebugMode) {
                    print(
                        'EmpresaService: Sucesso com tipo de contratação alternativo!');
                  }

                  if (alternativeResponse.body.isNotEmpty) {
                    try {
                      return EmpresaModel.fromJson(
                          json.decode(alternativeResponse.body));
                    } catch (e) {
                      if (kDebugMode) {
                        print(
                            'EmpresaService: Erro ao converter resposta alternativa: $e');
                      }
                      return alternativeEmpresa;
                    }
                  } else {
                    return alternativeEmpresa;
                  }
                }
              }
            } catch (e) {
              if (kDebugMode) {
                print('EmpresaService: Erro ao processar resposta de erro: $e');
              }
              lastErrorMessage = 'Erro ao processar resposta: $e';
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('EmpresaService: Erro ao tentar $endpoint: $e');
          }
          lastErrorMessage = 'Erro na requisição: $e';
        }
      }

      // Se chegou aqui, nenhum endpoint funcionou
      throw Exception(
          'EmpresaService: Falha ao criar empresa: nenhum endpoint funcionou. Último status: $lastStatusCode, Último erro: $lastErrorMessage, Resposta: $lastResponseBody');
    } catch (e) {
      if (kDebugMode) {
        print('EmpresaService: Erro geral na requisição: $e');
      }
      throw Exception('EmpresaService: Erro ao criar empresa: $e');
    }
  }

  // Atualizar uma empresa existente
  Future<EmpresaModel> updateEmpresa(EmpresaModel empresa) async {
    if (kDebugMode) {
      print('EmpresaService: Atualizando empresa ID: ${empresa.empresaId}');
      print('EmpresaService: Dados: ${json.encode(empresa.toJson())}');
    }

    // Garantir que o tipo de contratação seja válido
    if (empresa.tipoContratacaoId == null || empresa.tipoContratacaoId <= 0) {
      if (kDebugMode) {
        print(
            'EmpresaService: Tipo de contratação inválido ou nulo: ${empresa.tipoContratacaoId}. Usando valor padrão 1 (CLT)');
      }
      empresa = EmpresaModel(
        empresaId: empresa.empresaId,
        usuarioId: empresa.usuarioId,
        nome: empresa.nome,
        cliente: empresa.cliente,
        valor: empresa.valor,
        valorVA: empresa.valorVA,
        ativo: empresa.ativo,
        tipoContratacaoId: 1, // Forçar para um valor válido (CLT)
        tipoContratacaoDescricao: empresa.tipoContratacaoDescricao,
        diaPagamento1: empresa.diaPagamento1,
        diaPagamento2: empresa.diaPagamento2,
        bancoId: empresa.bancoId,
        bancoNome: empresa.bancoNome,
      );
    }

    try {
      // Tentar com diferentes endpoints e métodos HTTP
      final endpoints = [
        _buildEndpointUrl('empresas/${empresa.empresaId}'),
        _buildEndpointUrl('empresas'),
      ];

      // Tentar diferentes métodos HTTP
      for (var endpoint in endpoints) {
        // Tentar com PUT
        try {
          if (kDebugMode) {
            print('EmpresaService: Tentando PUT para: $endpoint');
          }

          final response = await http.put(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
            body: json.encode(empresa.toJson()),
          );

          if (kDebugMode) {
            print(
                'EmpresaService: Status da resposta para PUT $endpoint: ${response.statusCode}');
            print(
                'EmpresaService: Corpo da resposta para PUT $endpoint: ${response.body}');
          }

          if (response.statusCode == 200 || response.statusCode == 204) {
            if (kDebugMode) {
              print('EmpresaService: Sucesso com PUT para: $endpoint');
            }

            if (response.statusCode == 204 || response.body.isEmpty) {
              // Se não retornar dados, retorne o objeto original
              return empresa;
            } else {
              try {
                return EmpresaModel.fromJson(json.decode(response.body));
              } catch (e) {
                if (kDebugMode) {
                  print(
                      'EmpresaService: Erro ao converter resposta para EmpresaModel: $e');
                }
                // Retornar o objeto original se não conseguir converter
                return empresa;
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('EmpresaService: Erro ao tentar PUT para $endpoint: $e');
          }
        }

        // Tentar com POST
        try {
          if (kDebugMode) {
            print('EmpresaService: Tentando POST para: $endpoint');
          }

          final response = await http.post(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
              'X-HTTP-Method-Override':
                  'PUT', // Alguns servidores suportam isso
            },
            body: json.encode(empresa.toJson()),
          );

          if (kDebugMode) {
            print(
                'EmpresaService: Status da resposta para POST $endpoint: ${response.statusCode}');
            print(
                'EmpresaService: Corpo da resposta para POST $endpoint: ${response.body}');
          }

          if (response.statusCode == 200 ||
              response.statusCode == 201 ||
              response.statusCode == 204) {
            if (kDebugMode) {
              print('EmpresaService: Sucesso com POST para: $endpoint');
            }

            if (response.statusCode == 204 || response.body.isEmpty) {
              // Se não retornar dados, retorne o objeto original
              return empresa;
            } else {
              try {
                return EmpresaModel.fromJson(json.decode(response.body));
              } catch (e) {
                if (kDebugMode) {
                  print(
                      'EmpresaService: Erro ao converter resposta para EmpresaModel: $e');
                }
                // Retornar o objeto original se não conseguir converter
                return empresa;
              }
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('EmpresaService: Erro ao tentar POST para $endpoint: $e');
          }
        }
      }

      throw Exception(
          'EmpresaService: Falha ao atualizar empresa: nenhum método ou endpoint funcionou');
    } catch (e) {
      if (kDebugMode) {
        print('EmpresaService: Erro geral na requisição de atualização: $e');
      }
      throw Exception('EmpresaService: Erro ao atualizar empresa: $e');
    }
  }

  // Excluir uma empresa
  Future<bool> deleteEmpresa(int empresaId, int usuarioId) async {
    if (kDebugMode) {
      print('EmpresaService: Excluindo empresa ID: $empresaId');
    }

    try {
      // Tentar com diferentes endpoints
      final endpoints = [
        _buildEndpointUrl('empresas/$empresaId'),
      ];

      for (var endpoint in endpoints) {
        if (kDebugMode) {
          print('EmpresaService: Tentando endpoint: $endpoint');
        }

        try {
          final response = await http.delete(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (kDebugMode) {
            print(
                'EmpresaService: Status da resposta para $endpoint: ${response.statusCode}');
            print(
                'EmpresaService: Corpo da resposta para $endpoint: ${response.body}');
          }

          if (response.statusCode == 200 || response.statusCode == 204) {
            if (kDebugMode) {
              print('EmpresaService: Sucesso com endpoint: $endpoint');
            }
            return true;
          }
        } catch (e) {
          if (kDebugMode) {
            print('EmpresaService: Erro ao tentar $endpoint: $e');
          }
        }
      }

      throw Exception(
          'EmpresaService: Falha ao excluir empresa: nenhum endpoint funcionou');
    } catch (e) {
      if (kDebugMode) {
        print('EmpresaService: Erro geral na requisição: $e');
      }
      throw Exception('EmpresaService: Erro ao excluir empresa: $e');
    }
  }

  // Obter tipos de contratação
  Future<List<ContractType>> getTiposContratacao() async {
    if (kDebugMode) {
      print('EmpresaService: Buscando tipos de contratação');
    }

    try {
      // Tentar com diferentes endpoints - agora usando o formato correto com underscore
      final endpoints = [
        _buildEndpointUrl('tipos_contratacao'),
        _buildEndpointUrl('tipos-contratacao'), // Manter como fallback
      ];

      List<ContractType> tiposContratacao = [];
      bool success = false;

      for (var endpoint in endpoints) {
        if (kDebugMode) {
          print('EmpresaService: Tentando endpoint: $endpoint');
        }

        try {
          final response = await http.get(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (kDebugMode) {
            print(
                'EmpresaService: Status da resposta para $endpoint: ${response.statusCode}');
            print(
                'EmpresaService: Corpo da resposta para $endpoint: ${response.body}');
          }

          if (response.statusCode == 200) {
            final List<dynamic> data = json.decode(response.body);

            // Mapear os dados para objetos ContractType
            tiposContratacao = data.map((json) {
              if (kDebugMode) {
                print('EmpresaService: Processando tipo de contratação: $json');
              }
              return ContractType.fromJson(json);
            }).toList();

            success = true;
            if (kDebugMode) {
              print('EmpresaService: Sucesso com endpoint: $endpoint');
              print(
                  'EmpresaService: Tipos de contratação encontrados: ${tiposContratacao.length}');
              for (var tipo in tiposContratacao) {
                print('EmpresaService: Tipo: ${tipo.id} - ${tipo.description}');
              }
            }
            break;
          }
        } catch (e) {
          if (kDebugMode) {
            print('EmpresaService: Erro ao tentar $endpoint: $e');
          }
        }
      }

      // Não filtrar os tipos de contratação, retornar todos os encontrados
      if (success && tiposContratacao.isNotEmpty) {
        if (kDebugMode) {
          print(
              'EmpresaService: Retornando ${tiposContratacao.length} tipos de contratação do servidor');
        }
        return tiposContratacao;
      } else {
        // Se não conseguimos obter do servidor, usamos os padrões
        if (kDebugMode) {
          print('EmpresaService: Usando tipos de contratação padrão');
        }
        return [
          ContractType(id: 1, description: 'CLT'),
          ContractType(id: 3, description: 'PJ'),
          ContractType(id: 4, description: 'Autônomo')
        ];
      }
    } catch (e) {
      if (kDebugMode) {
        print('EmpresaService: Erro geral na requisição: $e');
      }
      // Retornar tipos padrão em caso de erro
      return [
        ContractType(id: 1, description: 'CLT'),
        ContractType(id: 3, description: 'PJ'),
        ContractType(id: 4, description: 'Autônomo')
      ];
    }
  }

  // Obter bancos do usuário
  Future<List<BancoModel>> getBancos(int usuarioId) async {
    if (kDebugMode) {
      print('EmpresaService: Buscando bancos para o usuário ID: $usuarioId');
    }

    try {
      // Tentar com diferentes endpoints
      final endpoints = [
        _buildEndpointUrl('bancos'),
      ];

      List<BancoModel> bancos = [];
      bool success = false;

      for (var endpoint in endpoints) {
        if (kDebugMode) {
          print('EmpresaService: Tentando endpoint: $endpoint');
        }

        try {
          final response = await http.get(
            Uri.parse(endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );

          if (kDebugMode) {
            print(
                'EmpresaService: Status da resposta para $endpoint: ${response.statusCode}');
            print(
                'EmpresaService: Corpo da resposta para $endpoint: ${response.body}');
          }

          if (response.statusCode == 200) {
            final List<dynamic> data = json.decode(response.body);
            bancos = data
                .map((json) => BancoModel.fromJson(json))
                .where((banco) => banco.usuarioId == usuarioId)
                .toList();

            success = true;
            if (kDebugMode) {
              print('EmpresaService: Sucesso com endpoint: $endpoint');
              print('EmpresaService: Bancos encontrados: ${bancos.length}');
            }
            break;
          }
        } catch (e) {
          if (kDebugMode) {
            print('EmpresaService: Erro ao tentar $endpoint: $e');
          }
        }
      }

      if (success) {
        return bancos;
      } else {
        if (kDebugMode) {
          print(
              'EmpresaService: Nenhum endpoint funcionou. Retornando lista vazia.');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) {
        print('EmpresaService: Erro geral na requisição: $e');
      }
      return [];
    }
  }

  // Função auxiliar para limitar o tamanho de uma string
  int min(int a, int b) {
    return a < b ? a : b;
  }
}
