class Transaction {
  final int? id;
  final int accountId;
  final String title;
  final String description;
  final double amount;
  final String type;
  final DateTime date;

  Transaction({
    this.id,
    required this.accountId,
    required this.title,
    required this.description,
    required this.amount,
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'account_id': accountId,
      'title': title,
      'description': description,
      'amount': amount,
      'type': type,
      'date': date.toIso8601String(),
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      accountId: map['account_id'],
      title: map['title'],
      description: map['description'],
      amount: map['amount'],
      type: map['type'],
      date: DateTime.parse(map['date']),
    );
  }
}
