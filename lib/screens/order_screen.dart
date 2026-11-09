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
  final List<OrderTicket> pendingTickets;
  final OrderTicket? editingTicket;
  final bool Function() hasPendingTickets;
  final void Function(List<OrderItem>) onSendOrder;
  final void Function(OrderTicket) onPendingTicketChanged;
  final void Function(String) onPendingTicketRemoved;
  final Function(bool, double, bool, List<OrderItem>) onOrderChanged;

  const OrderScreen({
    super.key,
    required this.masterTable,
    required this.getMergedGroup,
    required this.onUnmergeAll,
    required this.onUnmergeSingle,
    required this.menu,
    required this.order,
    required this.pendingTickets,
    this.editingTicket,
    required this.hasPendingTickets,
    required this.onSendOrder,
    required this.onPendingTicketChanged,
    required this.onPendingTicketRemoved,
    required this.onOrderChanged,
  });

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _PendingItemRef {
  final OrderTicket ticket;
  final OrderItem item;

  const _PendingItemRef({required this.ticket, required this.item});
}

class _OrderScreenState extends State<OrderScreen> {
  late TextEditingController _tableNoteCtrl;
  late TextEditingController _searchCtrl;
  String searchQuery = '';
  final List<OrderItem> draftItems = [];

  List<_PendingItemRef> get _pendingItemRefs => [
        for (final ticket in widget.pendingTickets)
          if (ticket.id != widget.editingTicket?.id)
          for (final item in ticket.items)
            _PendingItemRef(ticket: ticket, item: item),
      ];

  @override
  void initState() {
    super.initState();
    _tableNoteCtrl = TextEditingController(text: widget.order.note);
    _searchCtrl = TextEditingController();
    if (widget.editingTicket != null) {
      draftItems.addAll(widget.editingTicket!.items.map(_copyItem));
      _tableNoteCtrl.text = widget.editingTicket!.tableNote;
    }

  }

  @override
  void dispose() {
    _tableNoteCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  double get draftTotal =>
      draftItems.fold(0.0, (sum, i) => sum + i.totalPrice);
  double get total =>
      widget.order.items.fold(0.0, (sum, i) => sum + i.totalPrice);
  double get pendingTotal {
    var value = 0.0;
    for (final ticket in widget.pendingTickets) {
      if (ticket.id == widget.editingTicket?.id) {
        value += draftTotal;
      } else {
        value += ticket.items.fold(0.0, (sum, item) => sum + item.totalPrice);
      }
    }
    if (widget.editingTicket == null) value += draftTotal;
    return value;
  }

  OrderItem _copyItem(OrderItem item) => OrderItem(
        productId: item.productId,
        name: item.name,
        price: item.price,
        quantity: item.quantity,
        note: item.note,
      );

  void _addDraftItem(OrderItem item) {
    setState(() {
      for (final existing in draftItems) {
        if (existing.canGroupWith(item)) {
          existing.quantity += item.quantity;
          return;
        }
      }
      draftItems.add(item);
    });
  }

  void _sendDraft() {
    if (widget.editingTicket != null) {
      final ticket = widget.editingTicket!;
      ticket.items
        ..clear()
        ..addAll(draftItems.map(_copyItem));
      ticket.tableNote = _tableNoteCtrl.text.trim();
      if (ticket.items.isEmpty) {
        widget.onPendingTicketRemoved(ticket.id);
      } else {
        widget.onPendingTicketChanged(ticket);
      }
      if (draftItems.isEmpty) return;
    } else if (draftItems.isEmpty) {
      return;
    } else {
      widget.onSendOrder(draftItems.map(_copyItem).toList());
    }
    setState(() => draftItems.clear());
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Order sent to Pending Tickets'),
          backgroundColor: AppColors.electricCyan),
    );
  }

  void _editPendingItem(_PendingItemRef ref) {
    OrderDialogs.showEditOrderItemDialog(
      context: context,
      item: ref.item,
      onSave: (updated) {
        setState(() {
          final index = ref.ticket.items.indexOf(ref.item);
          if (index != -1) ref.ticket.items[index] = updated;
        });
        widget.onPendingTicketChanged(ref.ticket);
      },
      onDelete: () {
        setState(() => ref.ticket.items.remove(ref.item));
        if (ref.ticket.items.isEmpty) {
          widget.onPendingTicketRemoved(ref.ticket.id);
        } else {
          widget.onPendingTicketChanged(ref.ticket);
        }
      },
    );
  }

  void _editDraftItem(int index) {
    final item = draftItems[index];
    OrderDialogs.showEditOrderItemDialog(
      context: context,
      item: item,
      onSave: (updated) => setState(() => draftItems[index] = updated),
      onDelete: () => setState(() => draftItems.removeAt(index)),
    );
  }

  void _openEditProductDialog(Product item) {
    OrderDialogs.showEditProductDialog(
      context: context,
      item: item,
      onAdd: (OrderItem newItem) {
        _addDraftItem(newItem);
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
    if (widget.hasPendingTickets()) {
      _showPendingPaymentWarning();
      return;
    }
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

  void _showPendingPaymentWarning() {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Payment blocked'),
        content: const Text(
            'This table has unconfirmed pending orders. Please confirm or discard them first.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<TableModel> mergedGroup = widget.getMergedGroup();
    final bool isMerged = mergedGroup.length > 1;
    final String titleNames = mergedGroup.map((t) => t.name).join(' + ');

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) _sendDraft();
      },
      child: Scaffold(
      appBar: AppBar(
        title: Text('$titleNames - Order'),
        actions: [
          if (draftItems.isNotEmpty)
            TextButton.icon(
              onPressed: _sendDraft,
              style: TextButton.styleFrom(
                  foregroundColor: AppColors.electricCyan),
              icon: const Icon(Icons.send),
              label: const Text('Send Order'),
            ),
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
                if (widget.editingTicket != null) {
                  widget.editingTicket!.tableNote = val;
                  widget.onPendingTicketChanged(widget.editingTicket!);
                } else {
                  widget.order.note = val;
                }
                widget.onOrderChanged(false, 0.0, false, []);
              },
            ),
          ),
          if (widget.pendingTickets.any((ticket) =>
              ticket.id != widget.editingTicket?.id &&
              ticket.tableNote.trim().isNotEmpty))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Pending table note: ${widget.pendingTickets.where((ticket) => ticket.id != widget.editingTicket?.id && ticket.tableNote.trim().isNotEmpty).map((ticket) => ticket.tableNote).join(' | ')}',
                  style: const TextStyle(
                      color: AppColors.amber, fontWeight: FontWeight.bold),
                ),
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
                                    _addDraftItem(OrderItem(
                                      productId: item.id,
                                      name: item.name,
                                      price: item.price,
                                      quantity: 1,
                                    ));
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
            child: draftItems.isEmpty &&
                    widget.order.items.isEmpty &&
                    _pendingItemRefs.isEmpty
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
                    itemCount: draftItems.length +
                        widget.order.items.length +
                        _pendingItemRefs.length,
                    itemBuilder: (context, i) {
                      final isDraft = i < draftItems.length;
                      final confirmedIndex = i - draftItems.length;
                      final isConfirmed =
                          !isDraft && confirmedIndex < widget.order.items.length;
                      final pendingIndex = confirmedIndex - widget.order.items.length;
                      final pendingRef =
                          !isDraft && !isConfirmed ? _pendingItemRefs[pendingIndex] : null;
                      final item = isDraft
                          ? draftItems[i]
                          : isConfirmed
                              ? widget.order.items[confirmedIndex]
                              : pendingRef!.item;
                      return ListTile(
                        dense: true,
                        title: Text(
                          '${isDraft || pendingRef != null ? 'DRAFT • ' : ''}${item.quantity}x ${item.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: item.note.isNotEmpty
                            ? Text(
                                isDraft || pendingRef != null
                                    ? 'Draft • Note: ${item.note}'
                                    : item.note,
                                style: TextStyle(
                                    color: isDraft || pendingRef != null
                                        ? AppColors.electricCyan
                                        : AppColors.steelGrey,
                                    fontSize: 12))
                            : Text(
                                isDraft || pendingRef != null
                                    ? 'Draft / Unconfirmed'
                                    : 'On table bill',
                                style: TextStyle(
                                    color: isDraft
                                        ? AppColors.electricCyan
                                        : AppColors.steelGrey,
                                    fontSize: 12)),
                        onTap: isDraft
                            ? () => _editDraftItem(i)
                            : pendingRef != null
                                ? () => _editPendingItem(pendingRef)
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
                                    if (isDraft) {
                                      draftItems.removeAt(i);
                                    } else if (pendingRef != null) {
                                      pendingRef.ticket.items.remove(pendingRef.item);
                                    } else {
                                      widget.order.items
                                          .removeAt(i - draftItems.length);
                                    }
                                  }
                                  if (pendingRef != null) {
                                    if (pendingRef.ticket.items.isEmpty) {
                                      widget.onPendingTicketRemoved(
                                          pendingRef.ticket.id);
                                    } else {
                                      widget.onPendingTicketChanged(
                                          pendingRef.ticket);
                                    }
                                  }
                                });
                                if (pendingRef != null) {
                                  widget.onPendingTicketChanged(pendingRef.ticket);
                                } else if (!isDraft) {
                                  widget.onOrderChanged(false, 0.0, false, []);
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline,
                                  color: AppColors.emerald, size: 20),
                              onPressed: () {
                                setState(() {
                                  item.quantity++;
                                });
                                if (pendingRef != null) {
                                  widget.onPendingTicketChanged(pendingRef.ticket);
                                } else if (!isDraft) {
                                  widget.onOrderChanged(false, 0.0, false, []);
                                }
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Confirmed: ${total.toStringAsFixed(2)} €',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.bold)),
                        Text(
                            'Pending / Draft: ${pendingTotal.toStringAsFixed(2)} €',
                            style: const TextStyle(
                                color: AppColors.electricCyan)),
                      ],
                    ),
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
                            if (widget.hasPendingTickets()) {
                              _showPendingPaymentWarning();
                              return;
                            }
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
    ),
    );
  }
}