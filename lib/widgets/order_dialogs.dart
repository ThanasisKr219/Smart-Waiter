import 'dart:math';
import 'package:flutter/material.dart';
import '../models/pos_models.dart';

class OrderDialogs {
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
                      color: Colors.blueGrey.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Ποσότητα:',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: Colors.redAccent),
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
                                  color: Colors.green),
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
                      labelText: 'Τιμή Μονάδας (€)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Σχόλιο (π.χ. Μέτριος, χωρίς πάγο)',
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
                child: const Text('Άκυρο'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.add),
                label: Text('Προσθήκη ($selectedQty)'),
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
        title: const Text('Διαχωρισμός Τραπεζιών'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
                'Τα παρακάτω τραπέζια είναι ενωμένα στον λογαριασμό του "${masterTable.name}":'),
            const SizedBox(height: 12),
            for (final t in group)
              if (t.id != masterTable.id)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.table_bar, color: Colors.teal),
                  title: Text(t.name,
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  trailing: TextButton.icon(
                    icon: const Icon(Icons.link_off,
                        size: 18, color: Colors.orange),
                    label: const Text('Αποδέσμευση',
                        style: TextStyle(color: Colors.orange)),
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
            child: const Text('Κλείσιμο'),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.link_off),
            label: const Text('Διαχωρισμός Όλων'),
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
            title: const Text('Μερική Εξόφληση'),
            content: Container(
              width: double.maxFinite,
              constraints: const BoxConstraints(maxHeight: 340),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Επιλέξτε ποσότητες προς πληρωμή:',
                      style: TextStyle(fontSize: 13, color: Colors.grey)),
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
                  Text('Σύνολο Πληρωμής: ${selectedTotal.toStringAsFixed(2)}€',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Άκυρο'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white),
                onPressed: selectedTotal == 0
                    ? null
                    : () {
                        onConfirmPayment(selectedQuantities, selectedTotal);
                        Navigator.pop(ctx);
                      },
                child: const Text('Πληρωμή'),
              ),
            ],
          );
        },
      ),
    );
  }
}