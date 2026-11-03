import 'package:flutter/material.dart';
import '../../models/pos_models.dart';
import '../../widgets/empty_state_widget.dart';

class ShiftTab extends StatelessWidget {
  final double shiftTotal;
  final int shiftTransactionsCount;
  final int shiftClosedTables;
  final int shiftTotalItems;
  final List<ShiftTransaction> shiftLog;
  final VoidCallback onResetShift;

  const ShiftTab({
    super.key,
    required this.shiftTotal,
    required this.shiftTransactionsCount,
    required this.shiftClosedTables,
    required this.shiftTotalItems,
    required this.shiftLog,
    required this.onResetShift,
  });

  Widget _statBoxPremium(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Colors.white70),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.white70),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final double avg =
        shiftClosedTables > 0 ? (shiftTotal / shiftClosedTables) : 0.0;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          Card(
            elevation: 4,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF2C3E50), Color(0xFF3498DB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
              child: Column(
                children: [
                  const Text('ΣΥΝΟΛΙΚΟΣ ΤΖΙΡΟΣ ΒΑΡΔΙΑΣ',
                      style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Text(
                    '${shiftTotal.toStringAsFixed(2)} €',
                    style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const Divider(color: Colors.white24, height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statBoxPremium(Icons.point_of_sale, 'Συναλλαγές',
                          '$shiftTransactionsCount'),
                      _statBoxPremium(
                          Icons.table_bar, 'Τραπέζια', '$shiftClosedTables'),
                      _statBoxPremium(
                          Icons.local_cafe, 'Προϊόντα', '$shiftTotalItems'),
                      _statBoxPremium(
                          Icons.analytics, 'Μ.Ο', '${avg.toStringAsFixed(1)}€'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('   Ιστορικό Παραγγελιών',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
          ),
          Expanded(
            child: shiftLog.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.receipt_long, message: 'Καμία Συναλλαγή')
                : ListView.builder(
                    itemCount: shiftLog.length,
                    itemBuilder: (context, i) {
                      final log = shiftLog[i];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 4, horizontal: 4),
                        child: ExpansionTile(
                          leading: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: log.type == 'Ολική'
                                  ? Colors.green
                                  : Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              log.type,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${log.time.hour.toString().padLeft(2, '0')}:${log.time.minute.toString().padLeft(2, '0')} - ${log.tableName}',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ),
                              ),
                              Text(
                                '${log.amount.toStringAsFixed(2)} €',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87),
                              ),
                            ],
                          ),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: Colors.grey.shade50,
                              width: double.infinity,
                              child: Text(
                                log.items.map((it) {
                                  return it.note.isEmpty
                                      ? '${it.quantity}x ${it.name}'
                                      : '${it.quantity}x ${it.name} (${it.note})';
                                }).join(', '),
                                style: const TextStyle(
                                    fontStyle: FontStyle.italic),
                              ),
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.print),
                label: const Text('Κλείσιμο Βάρδιας (Μηδενισμός Ζ)',
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Λήξη Βάρδιας'),
                      content: const Text('Σίγουρα θέλετε να μηδενίσετε;'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Άκυρο'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                              foregroundColor: Colors.white),
                          onPressed: () {
                            onResetShift();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Μηδενισμός'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}