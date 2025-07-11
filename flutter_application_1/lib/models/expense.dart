class Expense {
  final String id;
  final double amount;
  final String category;
  final String description;
  final DateTime date;
  final String? upiTransactionId;
  final bool isAutoDetected;

  Expense({
    required this.id,
    required this.amount,
    required this.category,
    required this.description,
    required this.date,
    this.upiTransactionId,
    this.isAutoDetected = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date.toIso8601String(),
      'upiTransactionId': upiTransactionId,
      'isAutoDetected': isAutoDetected,
    };
  }

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      amount: json['amount'].toDouble(),
      category: json['category'],
      description: json['description'],
      date: DateTime.parse(json['date']),
      upiTransactionId: json['upiTransactionId'],
      isAutoDetected: json['isAutoDetected'] ?? false,
    );
  }
} 