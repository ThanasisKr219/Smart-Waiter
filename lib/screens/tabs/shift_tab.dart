import 'package:flutter/material.dart';
import '../../models/pos_models.dart';
import '../../widgets/empty_state_widget.dart';
import '../../theme/app_theme.dart';

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
        Icon(icon, size: 28, color: AppColors.frostWhite),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
              fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.frostWhite),
        ),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.frostWhite),
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
                  colors: [AppColors.deepSlateNavy, AppColors.electricCyan],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              padding:
                  const EdgeInsets.symmetric(vertical: 24.0, horizontal: 16),
              child: Column(
                children: [
                  const Text('TOTAL SHIFT SALES',
                      style: TextStyle(
                          fontSize: 14,
                          color: AppColors.frostWhite,
                          letterSpacing: 1.2)),
                  const SizedBox(height: 8),
                  Text(
                    '${shiftTotal.toStringAsFixed(2)} €',
                    style: const TextStyle(
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        color: AppColors.frostWhite),
                  ),
                  const Divider(color: AppColors.steelGrey, height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _statBoxPremium(Icons.point_of_sale, 'Transactions',
                          '$shiftTransactionsCount'),
                      _statBoxPremium(
                          Icons.table_bar, 'Tables', '$shiftClosedTables'),
                      _statBoxPremium(
                          Icons.local_cafe, 'Products', '$shiftTotalItems'),
                      _statBoxPremium(
                          Icons.analytics, 'Average', '${avg.toStringAsFixed(1)}€'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text('   Order History',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.frostWhite)),
          ),
          Expanded(
            child: shiftLog.isEmpty
                ? const EmptyStateWidget(
                    icon: Icons.receipt_long, message: 'No transactions')
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
                              color: (log.type == 'Full' || log.type == 'Ολική')
                                  ? AppColors.emerald
                                  : AppColors.amber,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              log.type,
                              style: const TextStyle(
                                  color: AppColors.midnightNavy,
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
                                    color: AppColors.frostWhite),
                              ),
                            ],
                          ),
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              color: AppColors.deepSlateNavy,
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
                label: const Text('Close Shift (Reset Z)',
                    style: TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coralRed,
                  foregroundColor: AppColors.frostWhite,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Close Shift'),
                      content: const Text('Are you sure you want to reset it?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.coralRed,
                              foregroundColor: AppColors.frostWhite),
                          onPressed: () {
                            onResetShift();
                            Navigator.pop(ctx);
                          },
                          child: const Text('Reset'),
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