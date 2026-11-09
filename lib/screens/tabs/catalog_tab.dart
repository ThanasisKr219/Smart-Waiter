import 'package:flutter/material.dart';
import '../../models/pos_models.dart';
import '../../widgets/empty_state_widget.dart';
import '../../theme/app_theme.dart';

class CatalogTab extends StatelessWidget {
  final List<Category> menu;

  const CatalogTab({super.key, required this.menu});

  @override
  Widget build(BuildContext context) {
    if (menu.isEmpty) {
      return const EmptyStateWidget(
          icon: Icons.menu_book, message: 'The catalog is empty');
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: menu.length,
      itemBuilder: (context, i) {
        final cat = menu[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const Divider(),
                if (cat.items.isEmpty)
                  const Text('No products available',
                      style: TextStyle(color: AppColors.steelGrey)),
                for (final item in cat.items)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(item.name),
                        Text('${item.price.toStringAsFixed(2)} €',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.emerald)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}