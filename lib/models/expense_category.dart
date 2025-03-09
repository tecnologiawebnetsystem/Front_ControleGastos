class ExpenseCategory {
  int? id;
  String name;
  int coefficient;

  ExpenseCategory({
    this.id,
    required this.name,
    required this.coefficient,
  });

  factory ExpenseCategory.fromJson(Map<String, dynamic> json) {
    return ExpenseCategory(
      id: json['id'] ??
          json['categoriaId'] ??
          json['CategoriaID'] ??
          json['Id'],
      name: json['name'] ?? json['nome'] ?? json['Nome'] ?? '',
      coefficient: json['coefficient'] ??
          json['coeficiente'] ??
          json['Coeficiente'] ??
          1,
    );
  }

  Map<String, dynamic> toJson() {
    // Criar um mapa base sem o ID, usando a convenção de nomenclatura Pascal Case
    final Map<String, dynamic> data = {
      'Nome': name,
      'Coeficiente': coefficient,
    };

    // Adicionar o ID apenas se não for nulo
    if (id != null) {
      data['Id'] = id;
    }

    return data;
  }

  @override
  String toString() {
    return 'ExpenseCategory{id: $id, name: $name, coefficient: $coefficient}';
  }

  // Método para criar uma cópia com alterações
  ExpenseCategory copyWith({
    int? id,
    String? name,
    int? coefficient,
  }) {
    return ExpenseCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      coefficient: coefficient ?? this.coefficient,
    );
  }
}
