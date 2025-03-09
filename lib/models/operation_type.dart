class OperationType {
  int? id;
  String description;
  int coefficient;

  OperationType({
    this.id,
    required this.description,
    this.coefficient = 1,
  });

  factory OperationType.fromJson(Map<String, dynamic> json, {int? mockId}) {
    // Debug print to see what's coming from the API
    print('OperationType.fromJson received: $json');

    // Try to extract ID from various possible field names
    var extractedId;

    // Check all possible ID field names in order of priority
    if (json.containsKey('TipoOperacaoID')) {
      extractedId = json['TipoOperacaoID'];
      print('Found ID in TipoOperacaoID: $extractedId');
    } else if (json.containsKey('tipoOperacaoID')) {
      extractedId = json['tipoOperacaoID'];
      print('Found ID in tipoOperacaoID: $extractedId');
    } else if (json.containsKey('TipoOperacaoId')) {
      extractedId = json['TipoOperacaoId'];
      print('Found ID in TipoOperacaoId: $extractedId');
    } else if (json.containsKey('tipoOperacaoId')) {
      extractedId = json['tipoOperacaoId'];
      print('Found ID in tipoOperacaoId: $extractedId');
    } else if (json.containsKey('id')) {
      extractedId = json['id'];
      print('Found ID in id: $extractedId');
    } else if (json.containsKey('Id')) {
      extractedId = json['Id'];
      print('Found ID in Id: $extractedId');
    } else if (json.containsKey('tiposOperacaoId')) {
      extractedId = json['tiposOperacaoId'];
      print('Found ID in tiposOperacaoId: $extractedId');
    } else if (json.containsKey('TiposOperacaoId')) {
      extractedId = json['TiposOperacaoId'];
      print('Found ID in TiposOperacaoId: $extractedId');
    }

    // Convert to int if it's a string
    int? parsedId;
    if (extractedId != null) {
      if (extractedId is int) {
        parsedId = extractedId;
      } else if (extractedId is String) {
        parsedId = int.tryParse(extractedId);
      }
    }

    // Use the mock ID if provided and no real ID was found
    if (parsedId == null && mockId != null) {
      parsedId = mockId;
      print('Using mock ID: $mockId');
    }

    print('Final ID: $parsedId');

    // Extract description from various possible field names
    String desc = '';
    if (json.containsKey('description')) {
      desc = json['description'];
    } else if (json.containsKey('descricao')) {
      desc = json['descricao'];
    } else if (json.containsKey('Descricao')) {
      desc = json['Descricao'];
    } else if (json.containsKey('nome')) {
      desc = json['nome'];
    } else if (json.containsKey('Nome')) {
      desc = json['Nome'];
    }

    // Extract coefficient from various possible field names
    int coef = 1;
    if (json.containsKey('coefficient')) {
      coef = json['coefficient'] is int
          ? json['coefficient']
          : int.tryParse(json['coefficient'].toString()) ?? 1;
    } else if (json.containsKey('coeficiente')) {
      coef = json['coeficiente'] is int
          ? json['coeficiente']
          : int.tryParse(json['coeficiente'].toString()) ?? 1;
    } else if (json.containsKey('Coeficiente')) {
      coef = json['Coeficiente'] is int
          ? json['Coeficiente']
          : int.tryParse(json['Coeficiente'].toString()) ?? 1;
    }

    return OperationType(
      id: parsedId,
      description: desc,
      coefficient: coef,
    );
  }

  Map<String, dynamic> toJson() {
    // Use the exact field names expected by the backend
    final Map<String, dynamic> data = {
      'Descricao': description,
      'Coeficiente': coefficient,
    };

    // Adicionar o ID apenas se não for nulo
    if (id != null) {
      data['TipoOperacaoID'] = id;
    }

    return data;
  }

  @override
  String toString() {
    return 'OperationType{id: $id, description: $description, coefficient: $coefficient}';
  }

  // Método para criar uma cópia com alterações
  OperationType copyWith({
    int? id,
    String? description,
    int? coefficient,
  }) {
    return OperationType(
      id: id ?? this.id,
      description: description ?? this.description,
      coefficient: coefficient ?? this.coefficient,
    );
  }
}
