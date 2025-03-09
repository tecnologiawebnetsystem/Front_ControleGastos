class PaymentStatus {
  int? id;
  String description;

  PaymentStatus({
    this.id,
    required this.description,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> json, {int? mockId}) {
    // Debug print to see what's coming from the API
    print('PaymentStatus.fromJson received: $json');

    // Try to extract ID from various possible field names
    var extractedId;

    // Check all possible ID field names in order of priority
    if (json.containsKey('statusPagamentoID')) {
      extractedId = json['statusPagamentoID'];
      print('Found ID in statusPagamentoID: $extractedId');
    } else if (json.containsKey('StatusPagamentoID')) {
      extractedId = json['StatusPagamentoID'];
      print('Found ID in StatusPagamentoID: $extractedId');
    } else if (json.containsKey('statusPagamentoId')) {
      extractedId = json['statusPagamentoId'];
      print('Found ID in statusPagamentoId: $extractedId');
    } else if (json.containsKey('StatusPagamentoId')) {
      extractedId = json['StatusPagamentoId'];
      print('Found ID in StatusPagamentoId: $extractedId');
    } else if (json.containsKey('id')) {
      extractedId = json['id'];
      print('Found ID in id: $extractedId');
    } else if (json.containsKey('Id')) {
      extractedId = json['Id'];
      print('Found ID in Id: $extractedId');
    } else if (json.containsKey('statusId')) {
      extractedId = json['statusId'];
      print('Found ID in statusId: $extractedId');
    } else if (json.containsKey('StatusId')) {
      extractedId = json['StatusId'];
      print('Found ID in StatusId: $extractedId');
    } else {
      print('No ID field found in JSON. Available keys: ${json.keys.toList()}');
    }

    // Convert to int if it's a string
    int? parsedId;
    if (extractedId != null) {
      if (extractedId is int) {
        parsedId = extractedId;
        print('ID is already an int: $parsedId');
      } else if (extractedId is String) {
        parsedId = int.tryParse(extractedId);
        print('Converted string ID to int: $parsedId');
      } else {
        print('ID is neither int nor string, but: ${extractedId.runtimeType}');
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
      print('Found description in description: $desc');
    } else if (json.containsKey('descricao')) {
      desc = json['descricao'];
      print('Found description in descricao: $desc');
    } else if (json.containsKey('Descricao')) {
      desc = json['Descricao'];
      print('Found description in Descricao: $desc');
    } else if (json.containsKey('nome')) {
      desc = json['nome'];
      print('Found description in nome: $desc');
    } else if (json.containsKey('Nome')) {
      desc = json['Nome'];
      print('Found description in Nome: $desc');
    } else {
      print(
          'No description field found in JSON. Available keys: ${json.keys.toList()}');
    }

    return PaymentStatus(
      id: parsedId,
      description: desc,
    );
  }

  Map<String, dynamic> toJson() {
    // Use the exact field names expected by the backend
    final Map<String, dynamic> data = {
      'Descricao': description,
    };

    // Adicionar o ID apenas se não for nulo
    if (id != null) {
      data['StatusPagamentoID'] = id;
    }

    print('PaymentStatus.toJson: $data');
    return data;
  }

  @override
  String toString() {
    return 'PaymentStatus{id: $id, description: $description}';
  }

  // Método para criar uma cópia com alterações
  PaymentStatus copyWith({
    int? id,
    String? description,
  }) {
    return PaymentStatus(
      id: id ?? this.id,
      description: description ?? this.description,
    );
  }
}
