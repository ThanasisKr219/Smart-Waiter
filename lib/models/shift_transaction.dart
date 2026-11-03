import 'order_models.dart';

class ShiftTransaction {
  String id;
  DateTime time;
  String tableName;
  String type;
  double amount;
  List<OrderItem> items;

  ShiftTransaction({
    required this.id,
    required this.time,
    required this.tableName,
    required this.type,
    required this.amount,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'time': time.toIso8601String(),
        'tableName': tableName,
        'type': type,
        'amount': amount,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory ShiftTransaction.fromJson(Map<String, dynamic> json) =>
      ShiftTransaction(
        id: json['id'],
        time: DateTime.parse(json['time']),
        tableName: json['tableName'],
        type: json['type'],
        amount: (json['amount'] as num).toDouble(),
        items: (json['items'] as List)
            .map((e) => OrderItem.fromJson(e))
            .toList(),
      );
}