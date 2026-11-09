import 'package:flutter/material.dart';
import '../models/pos_models.dart';
import '../utils/smart_search_helper.dart';
import '../widgets/order_dialogs.dart';
import '../theme/app_theme.dart';

class OrderScreen extends StatefulWidget {
  final TableModel masterTable;
  final List<TableModel> Function() getMergedGroup;
  final VoidCallback onUnmergeAll;
  final Function(TableModel) onUnmergeSingle;
  final List<Category> menu;
  final TableOrder order;
  final Function(bool, double, bool, List<OrderItem>) onOrderChanged;

  const OrderScreen({
    super.key,
    required this.masterTable,
    required this.getMergedGroup,
    required this.onUnmergeAll,
    required this.onUnmergeSingle,
    required this.menu,
    required this.order,
    required this.onOrderChanged,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  late TextEditingController _tableNoteCtrl;
  late TextEditingController _searchCtrl;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tableNoteCtrl = TextEditingController(text: widget.order.note);
    _searchCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _tableNoteCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  double get total =>
      widget.order.items.fold(0.0, (sum, i) => sum + i.totalPrice);

  void _openEditProductDialog(Product item) {
    OrderDialogs.showEditProductDialog(
      context: context,
      item: item,
      onAdd: (OrderItem newItem) {
        setState(() {
          widget.order.addOrGroupItem(newItem);
        });
        widget.onOrderChanged(false, 0.0, false, []);
      },
    );
  }

  void _openUnmergeModal(List<TableModel> group) {
    OrderDialogs.showUnmergeModal(
      context: context,
      masterTable: widget.masterTable,
      group: group,
      onUnmergeSingle: (t) {
        widget.onUnmergeSingle(t);
        setState(() {});
      },
      onUnmergeAll: () {
        widget.onUnmergeAll();
        setState(() {});
      },
    );
  }

  void _openPartialPaymentDialog() {
    OrderDialogs.showPartialPaymentDialog(
      context: context,
      items: widget.order.items,
      onConfirmPayment: (selectedQuantities, selectedTotal) {
        List<OrderItem> paidItems = [];
        setState(() {
          for (int i = widget.order.items.length - 1; i >= 0; i--) {
            final selQty = selectedQuantities[i];
            if (selQty > 0) {
              final current = widget.order.items[i];
              paidItems.add(
                OrderItem(
                  productId: current.productId,
                  name: current.name,
                  price: current.price,
                  quantity: selQty,
                  note: current.note,
                ),
              );
              if (selQty == current.quantity) {
                widget.order.items.removeAt(i);
              } else {
                current.quantity -= selQty;
              }
            }
          }
        });
        final isFull = widget.order.items.isEmpty;
        if (isFull) {
          widget.order.note = '';
          _tableNoteCtrl.clear();
        }
        widget.onOrderChanged(true, selectedTotal, isFull, paidItems);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<TableModel> mergedGroup = widget.getMergedGroup();
    final bool isMerged = mergedGroup.length > 1;
    final String titleNames = mergedGroup.map((t) => t.name).join(' + ');

    return Scaffold(
      appBar: AppBar(
        title: Text('$titleNames - Order'),
        actions: [
          if (isMerged)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                style: TextButton.styleFrom(
                  backgroundColor: AppColors.deepSlateNavy,
                  foregroundColor: AppColors.electricCyan,
                ),
                icon: const Icon(Icons.link_off, size: 18),
                label: const Text('Unmerge',
                    style:
                        TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: () => _openUnmergeModal(mergedGroup),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 4),
            child: TextField(
              controller: _tableNoteCtrl,
              decoration: InputDecoration(
                hintText: 'Table note... (e.g. Complimentary)',
                prefixIcon: const Icon(Icons.note_alt_outlined, size: 20),
                isDense: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onChanged: (val) {
                widget.order.note = val;
                widget.onOrderChanged(false, 0.0, false, []);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Smart Search (e.g. freddo, espresso, cappuccino)...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => searchQuery = '');
                        },
                      )
                    : null,
                isDense: true,
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                fillColor: AppColors.deepSlateNavy,
                filled: true,
              ),
              onChanged: (val) => setState(() => searchQuery = val),
            ),
          ),
          Expanded(
            flex: 3,
            child: widget.menu.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fastfood,
                            size: 60, color: AppColors.steelGrey),
                        const Text('The catalog is empty',
                            style: TextStyle(color: AppColors.steelGrey))
                      ],
                    ),
                  )
                : ListView(
                    children: widget.menu.map((cat) {
                      final filteredItems = cat.items
                          .where((i) =>
                              SmartSearchHelper.matches(i.name, searchQuery))
                          .toList();

                      if (filteredItems.isEmpty &&
                          searchQuery.trim().isNotEmpty) {
                        return const SizedBox.shrink();
                      }

                      return Card(
                        key: ValueKey('${cat.id}_${searchQuery.isNotEmpty}'),
                        margin: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        elevation: 1,
                        child: ExpansionTile(
                          initiallyExpanded: searchQuery.trim().isNotEmpty,
                          title: Text(cat.name,
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          children: filteredItems
                              .map(
                                (item) => ListTile(
                                  dense: true,
                                  title: Text(item.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600)),
                                  subtitle: const Text(
                                      'Tap = +1 | Long press = Quantity & Note',
                                      style: TextStyle(fontSize: 10)),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '${item.price.toStringAsFixed(2)} €',
                                        style: const TextStyle(
                                            color: AppColors.emerald,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.edit_note,
                                            color: AppColors.steelGrey, size: 20),
                                        tooltip: 'Quantity & Note',
                                        onPressed: () =>
                                            _openEditProductDialog(item),
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    setState(() {
                                      widget.order.addOrGroupItem(
                                        OrderItem(
                                          productId: item.id,
                                          name: item.name,
                                          price: item.price,
                                          quantity: 1,
                                        ),
                                      );
                                    });
                                    widget.onOrderChanged(
                                        false, 0.0, false, []);
                                  },
                                  onLongPress: () =>
                                      _openEditProductDialog(item),
                                ),
                              )
                              .toList(),
                        ),
                      );
                    }).toList(),
                  ),
          ),
          const Divider(thickness: 2, height: 1),
          Expanded(
            flex: 2,
            child: widget.order.items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt,
                            size: 50, color: AppColors.steelGrey),
                        const Text('This table has no order.',
                            style: TextStyle(color: AppColors.steelGrey))
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: widget.order.items.length,
                    itemBuilder: (context, i) {
                      final item = widget.order.items[i];
                      return ListTile(
                        dense: true,
                        title: Text(
                          '${item.quantity}x ${item.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: item.note.isNotEmpty
                            ? Text(item.note,
                                style: TextStyle(
                                    color: AppColors.steelGrey,
                                    fontSize: 12))
                            : null,
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${item.totalPrice.toStringAsFixed(2)} €',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline,
                                  color: AppColors.amber, size: 20),
                              onPressed: () {
                                setState(() {
                                  if (item.quantity > 1) {
                                    item.quantity--;
                                  } else {
                                    widget.order.items.removeAt(i);
                                  }
                                });
                                widget.onOrderChanged(false, 0.0, false, []);
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  color: AppColors.emerald, size: 20),
                              onPressed: () {
                                setState(() {
                                  item.quantity++;
                                });
                                widget.onOrderChanged(false, 0.0, false, []);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: AppColors.deepSlateNavy,
              boxShadow: [
                BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -4))
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: Text('Total: ${total.toStringAsFixed(2)} €',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.amber,
                      foregroundColor: AppColors.midnightNavy,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: total == 0 ? null : _openPartialPaymentDialog,
                    child: const Text('Partial'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.emerald,
                      foregroundColor: AppColors.midnightNavy,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                    onPressed: total == 0
                        ? null
                        : () {
                            showDialog(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Full Payment?'),
                                content: Text(
                                  isMerged
                                      ? 'Total: ${total.toStringAsFixed(2)}€\n(${mergedGroup.length} served tables will be recorded and automatically unmerged)'
                                      : 'Total: ${total.toStringAsFixed(2)}€',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx),
                                    child: const Text('Cancel'),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.emerald,
                                        foregroundColor: AppColors.midnightNavy),
                                    onPressed: () {
                                      final amountToPay = total;
                                      final paidItems = List<OrderItem>.from(
                                          widget.order.items);
                                      setState(() {
                                        widget.order.items.clear();
                                        widget.order.note = '';
                                        _tableNoteCtrl.clear();
                                      });
                                      widget.onOrderChanged(
                                          true, amountToPay, true, paidItems);
                                      Navigator.pop(ctx);
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Payment'),
                                  ),
                                ],
                              ),
                            );
                          },
                    child: const Text('Full Payment'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}