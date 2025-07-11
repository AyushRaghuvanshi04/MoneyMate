class Income {
  final String id;
  final String description;
  final double amount;
  final DateTime date;
  final String category;
  final bool isAutoDetected;

  Income({
    required this.id,
    required this.description,
    required this.amount,
    required this.date,
    required this.category,
    this.isAutoDetected = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
      'isAutoDetected': isAutoDetected,
    };
  }

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'],
      description: json['description'],
      amount: json['amount'].toDouble(),
      date: DateTime.parse(json['date']),
      category: json['category'],
      isAutoDetected: json['isAutoDetected'] ?? false,
    );
  }
} 