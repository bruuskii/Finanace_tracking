class Account {
  final int? id;
  final String name;
  final double balance;
  final String password;

  Account({
    this.id,
    required this.name,
    required this.balance,
    required this.password,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'password': password,
    };
  }

  factory Account.fromMap(Map<String, dynamic> map) {
    return Account(
      id: map['id'],
      name: map['name'],
      balance: map['balance'],
      password: map['password'] ?? '',
    );
  }

  Account copyWith({
    int? id,
    String? name,
    double? balance,
    String? password,
  }) {
    return Account(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      password: password ?? this.password,
    );
  }
}
