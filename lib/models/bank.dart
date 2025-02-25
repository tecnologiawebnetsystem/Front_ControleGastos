class Bank {
  final String code;
  final String name;

  Bank({required this.code, required this.name});

  factory Bank.fromJson(Map<String, dynamic> json) {
    return Bank(
      code: json['code'],
      name: json['name'],
    );
  }
}
