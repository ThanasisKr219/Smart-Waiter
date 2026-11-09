class OrderItem {
  String productId;
  String name;
  double price;
  int quantity;
  String note;

  OrderItem({
    this.productId = '',
    required this.name,
    required this.price,
    this.quantity = 1,
    this.note = '',
  });

  double get totalPrice => price * quantity;

  bool canGroupWith(OrderItem other) {
    if (name.trim().toLowerCase() != other.name.trim().toLowerCase()) {
      return false;
    }
    if ((price - other.price).abs() > 0.001) {
      return false;
    }
    if (note.trim().toLowerCase() != other.note.trim().toLowerCase()) {
      return false;
    }
    return true;
  }

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'name': name,
        'price': price,
        'quantity': quantity,
        'note': note,
      };

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        productId: json['productId'] ?? '',
        name: json['name'],
        price: (json['price'] as num).toDouble(),
        quantity: json['quantity'] ?? 1,
        note: json['note'] ?? '',
      );
}

class TableOrder {
  String note;
  List<OrderItem> items;

  TableOrder({
    this.note = '',
    required this.items,
  });

  void addOrGroupItem(OrderItem newItem) {
    for (var existing in items) {
      if (existing.canGroupWith(newItem)) {
        existing.quantity += newItem.quantity;
        return;
      }
    }
    items.add(
      OrderItem(
        productId: newItem.productId,
        name: newItem.name,
        price: newItem.price,
        quantity: newItem.quantity,
        note: newItem.note,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
        'note': note,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory TableOrder.fromJson(Map<String, dynamic> json) => TableOrder(
        note: json['note'] ?? '',
        items: (json['items'] as List)
            .map((e) => OrderItem.fromJson(e))
            .toList(),
      );
}

class OrderTicket {
  String id;
  String tableId;
  String tableName;
  String tableNote;
  DateTime timestamp;
  List<OrderItem> items;

  OrderTicket({
    required this.id,
    required this.tableId,
    required this.tableName,
    this.tableNote = '',
    required this.timestamp,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'tableId': tableId,
        'tableName': tableName,
        'tableNote': tableNote,
        'timestamp': timestamp.toIso8601String(),
        'items': items.map((item) => item.toJson()).toList(),
      };

  factory OrderTicket.fromJson(Map<String, dynamic> json) => OrderTicket(
        id: json['id'] ?? '',
        tableId: json['tableId'] ?? '',
        tableName: json['tableName'] ?? 'Unknown table',
        tableNote: json['tableNote'] ?? '',
        timestamp: DateTime.tryParse(json['timestamp'] ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        items: (json['items'] as List? ?? [])
            .map((item) => OrderItem.fromJson(item))
            .toList(),
      );
}