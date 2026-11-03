class Product {
  String id;
  String name;
  double price;

  Product({required this.id, required this.name, required this.price});

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
      };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
        id: json['id'],
        name: json['name'],
        price: (json['price'] as num).toDouble(),
      );
}