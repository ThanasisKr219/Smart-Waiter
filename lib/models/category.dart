import 'product.dart';

class Category {
  String id;
  String name;
  List<Product> items;

  Category({required this.id, required this.name, required this.items});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        id: json['id'],
        name: json['name'],
        items: (json['items'] as List).map((e) => Product.fromJson(e)).toList(),
      );
}