import 'dart:math';
import 'package:flutter/material.dart';
import '../models/pos_models.dart';
import '../theme/app_theme.dart';

class OrderDialogs {
  static void showEditOrderItemDialog({
    required BuildContext context,
    required OrderItem item,
    required void Function(OrderItem updated) onSave,
    required VoidCallback onDelete,
  }) {
    final quantityCtrl = TextEditingController(text: '${item.quantity}');
    final priceCtrl =
        TextEditingController(text: item.price.toStringAsFixed(2));
    final noteCtrl = TextEditingController(text: item.note);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Edit ${item.name}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: quantityCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Quantity', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                    labelText: 'Unit Price (€)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteCtrl,
                decoration: const InputDecoration(
                    labelText: 'Note', border: OutlineInputBorder()),
              ),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              onDelete();
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: AppColors.coralRed),
            icon: const Icon(Icons.delete_outline),
            label: const Text('Delete'),
          ),
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              final quantity = int.tryParse(quantityCtrl.text) ?? 0;
              final price = double.tryParse(
                      priceCtrl.text.trim().replaceAll(',', '.')) ??
                  item.price;
              if (quantity <= 0) {
                onDelete();
              } else {
                onSave(OrderItem(
                  productId: item.productId,
                  name: item.name,
                  price: max(0, price),
                  quantity: quantity,
                  note: noteCtrl.text.trim(),
                ));
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  static void showEditProductDialog({
    required BuildContext context,
    required Product item,
    required void Function(OrderItem newItem) onAdd,
  }) {
    final priceCtrl =
        TextEditingController(text: item.price.toStringAsFixed(2));
    final noteCtrl = TextEditingController();
    int selectedQty = 1;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.deepSlateNavy,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Quantity:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: AppColors.coralRed),
                              onPressed: selectedQty > 1
                                  ? () => setDialogState(() => selectedQty--)
                                  : null,
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Text(
                                '$selectedQty',
                                style: const TextStyle(
                                    fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  color: AppColors.emerald),
                              onPressed: () =>
                                  setDialogState(() => selectedQty++),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: priceCtrl,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'Unit Price (€)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Note (e.g. Medium, no ice)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.emerald,
                  foregroundColor: AppColors.midnightNavy,
                ),
                icon: const Icon(Icons.add),
                label: Text('Add ($selectedQty)'),
                onPressed: () {
                  final double parsedPrice = max(
                    0.0,
                    double.tryParse(priceCtrl.text.replaceAll(',', '.')) ??
                        item.price,
                  );

                  onAdd(
                    OrderItem(
                      productId: item.id,
                      name: item.name,
                      price: parsedPrice,
                      quantity: selectedQty,
                      note: noteCtrl.text.trim(),
                    ),
                  );
                  Navigator.pop(ctx);
                },
              ),
            ],
          );
        },
      ),
    );
  }

  static void showUnmergeModal({
    required BuildContext context,
    required TableModel masterTable,
    required List<TableModel> group,
    required void Function(TableModel) onUnmergeSingle,
    required VoidCallback onUnmergeAll,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unmerge Tables'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'The following tables are merged into "${masterTable.name}":'),
            const SizedBox(height: 12),
            for (final t in group)
              if (t.id != masterTable.id)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.table_bar, color: AppColors.electricCyan),
                  title: Text(t.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: TextButton.icon(
                    icon: const Icon(Icons.link_off,
                        size: 18, color: AppColors.amber),
                    label: const Text('Unmerge',
                        style: TextStyle(color: AppColors.amber)),
                    onPressed: () {
                      onUnmergeSingle(t);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coralRed,
              foregroundColor: AppColors.frostWhite,
            ),
            icon: const Icon(Icons.link_off),
            label: const Text('Unmerge All'),
            onPressed: () {
              onUnmergeAll();
              Navigator.pop(ctx);
            },
          ),
        ],
      ),
    );
  }

  static void showPartialPaymentDialog({
    required BuildContext context,
    required List<OrderItem> items,
    required void Function(List<int> selectedQuantities, double selectedTotal)
        onConfirmPayment,
  }) {
    List<int> selectedQuantities = List.generate(items.length, (i) => 0);

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          double selectedTotal = 0.0;
          for (int i = 0; i < items.length; i++) {
            selectedTotal += items[i].price * selectedQuantities[i];
          }
          return AlertDialog(
            title: const Text('Partial Payment'),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxHeight: 340),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select quantities to pay:',
                      style: TextStyle(fontSize: 13, color: AppColors.steelGrey)),
                  const SizedBox(height: 8),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, i) {
                        final item = items[i];
                        return ListTile(
                          dense: true,
                          contentPadding: EdgeInsets.zero,
                          title: Text(
                              '${item.name} (${item.price.toStringAsFixed(2)}€)'),
                          subtitle:
                              item.note.isNotEmpty ? Text(item.note) : null,
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: selectedQuantities[i] > 0
                                    ? () => setDialogState(
                                        () => selectedQuantities[i]--)
                                    : null,
                              ),
                              Text('${selectedQuantities[i]}/${item.quantity}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: selectedQuantities[i] < item.quantity
                                    ? () => setDialogState(
                                        () => selectedQuantities[i]++)
                                    : null,
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(),
                  Text('Payment Total: ${selectedTotal.toStringAsFixed(2)}€',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.amber,
                    foregroundColor: AppColors.midnightNavy),
                onPressed: selectedTotal == 0
                    ? null
                    : () {
                        onConfirmPayment(selectedQuantities, selectedTotal);
                        Navigator.pop(ctx);
                      },
                child: const Text('Payment'),
              ),
            ],
          );
        },
      ),
    );
  }
}