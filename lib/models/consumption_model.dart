import 'package:flutter/foundation.dart';

class Consumption {
  final int amount; // en ml
  final DateTime timestamp;

  Consumption({
    required this.amount,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Consumption.fromJson(Map<String, dynamic> json) {
    return Consumption(
      amount: json['amount'] as int,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class ConsumptionDay {
  final DateTime date;
  final List<Consumption> consumptions;

  ConsumptionDay({
    required this.date,
    required this.consumptions,
  });

  int get totalAmount => consumptions.fold(0, (sum, item) => sum + item.amount);
}