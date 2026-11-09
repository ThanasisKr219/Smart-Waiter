import 'package:flutter/material.dart';
import '../../models/pos_models.dart';
import '../../theme/app_theme.dart';
import '../../widgets/empty_state_widget.dart';

class PendingTicketsTab extends StatelessWidget {
  final List<OrderTicket> tickets;
  final void Function(OrderTicket) onConfirm;
  final void Function(OrderTicket) onReject;
  final void Function(OrderTicket) onEdit;

  const PendingTicketsTab({
    super.key,
    required this.tickets,
    required this.onConfirm,
    required this.onReject,
    required this.onEdit,
  });

  String _elapsed(DateTime timestamp) {
    final elapsed = DateTime.now().difference(timestamp);
    if (elapsed.inMinutes < 1) return 'just now';
    if (elapsed.inHours < 1) return '${elapsed.inMinutes}m ago';
    if (elapsed.inDays < 1) return '${elapsed.inHours}h ${elapsed.inMinutes % 60}m ago';
    return '${elapsed.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    if (tickets.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.receipt_long,
        message: 'No pending tickets',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: tickets.length,
      itemBuilder: (context, index) {
        final ticket = tickets[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(ticket.tableName,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    Text(_elapsed(ticket.timestamp),
                        style: const TextStyle(color: AppColors.electricCyan)),
                  ],
                ),
                const Divider(),
                if (ticket.tableNote.trim().isNotEmpty)
                  Text('Table note: ${ticket.tableNote}',
                      style: const TextStyle(
                          color: AppColors.amber,
                          fontWeight: FontWeight.bold)),
                ...ticket.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                              '${item.quantity}x ${item.name} - ${item.totalPrice.toStringAsFixed(2)} €'),
                          if (item.note.trim().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(left: 20),
                              child: Text('Note: ${item.note}',
                                  style: const TextStyle(
                                      color: AppColors.electricCyan)),
                            ),
                        ],
                      ),
                    )),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () => onEdit(ticket),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.electricCyan),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      onPressed: () => onReject(ticket),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.coralRed),
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: () => onConfirm(ticket),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.emerald,
                          foregroundColor: AppColors.midnightNavy),
                      icon: const Icon(Icons.check),
                      label: const Text('Confirm'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
