class ContractType {
  int? id;
  String description;

  ContractType({
    this.id,
    required this.description,
  });

  factory ContractType.fromJson(Map<String, dynamic> json, {int? mockId}) {
    // Debug print to see what's coming from the API
    print('ContractType.fromJson received: $json');

    // Try to extract ID from various possible field names
    var extractedId;

    // Check all possible ID field names in order of priority
    if (json.containsKey('TipoContratacaoID')) {
      extractedId = json[
          'TipoContratacaoID']; // Primeiro, tenta o formato exato do backend
    } else if (json.containsKey('tipoContratacaoID')) {
      extractedId = json['tipoContratacaoID'];
    } else if (json.containsKey('TiposContratacaoId')) {
      extractedId = json['TiposContratacaoId'];
    } else if (json.containsKey('tiposContratacaoId')) {
      extractedId = json['tiposContratacaoId'];
    } else if (json.containsKey('id')) {
      extractedId = json['id'];
    } else if (json.containsKey('Id')) {
      extractedId = json['Id'];
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

    return ContractType(
      id: parsedId,
      description: desc,
    );
  }

  Map<String, dynamic> toJson() {
    // Use the exact field names expected by the backend
    final Map<String, dynamic> data = {
      'Descricao': description,
    };

    // Adicionar o ID apenas se não for nulo, usando o nome correto do campo
    if (id != null) {
      data['TipoContratacaoID'] = id; // Usando o formato exato do backend
    }

    return data;
  }

  @override
  String toString() {
    return 'ContractType{id: $id, description: $description}';
  }

  // Método para criar uma cópia com alterações
  ContractType copyWith({
    int? id,
    String? description,
  }) {
    return ContractType(
      id: id ?? this.id,
      description: description ?? this.description,
    );
  }
}
