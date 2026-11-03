import 'package:flutter/material.dart';
import '../../models/pos_models.dart';
import '../../widgets/empty_state_widget.dart';

class SetupMenuTab extends StatelessWidget {
  final List<Category> menu;
  final Function(Category, String) onRenameCategory;
  final Function(Category) onDeleteCategory;
  final Function(Product, String, double) onEditProduct;
  final Function(Category, Product) onDeleteProduct;

  const SetupMenuTab({
    super.key,
    required this.menu,
    required this.onRenameCategory,
    required this.onDeleteCategory,
    required this.onEditProduct,
    required this.onDeleteProduct,
  });

  @override
  Widget build(BuildContext context) {
    if (menu.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.restaurant_menu,
        message: 'Press + to add a catalog',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (var cat in menu)
          Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            child: ExpansionTile(
              title: Text(cat.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      final c = TextEditingController(text: cat.name);
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Edit Category'),
                          content: TextField(controller: c),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                onRenameCategory(cat, c.text);
                                Navigator.pop(ctx);
                              },
                              child: const Text('Save'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => onDeleteCategory(cat),
                  ),
                ],
              ),
              children: cat.items.map((p) {
                return ListTile(
                  dense: true,
                  title: Text(p.name),
                  subtitle: Text('${p.price.toStringAsFixed(2)} €'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.edit, color: Colors.blue, size: 20),
                        onPressed: () {
                          final nc = TextEditingController(text: p.name);
                          final pc = TextEditingController(
                              text: p.price.toStringAsFixed(2));
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Edit Product'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: nc,
                                    decoration: const InputDecoration(
                                        labelText: 'Name'),
                                  ),
                                  TextField(
                                    controller: pc,
                                    keyboardType: const TextInputType
                                        .numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                        labelText: 'Price (€)'),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    final newPrice = double.tryParse(
                                            pc.text.replaceAll(',', '.')) ??
                                        p.price;
                                    onEditProduct(p, nc.text, newPrice);
                                    Navigator.pop(ctx);
                                  },
                                  child: const Text('Save'),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete,
                            color: Colors.red, size: 20),
                        onPressed: () => onDeleteProduct(cat, p),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }
}