import 'package:flutter/material.dart';
import '../../models/pos_models.dart';
import '../../widgets/empty_state_widget.dart';

class SetupMapTab extends StatelessWidget {
  final List<Space> spaces;
  final List<TableModel> tables;
  final Function(Space, String) onRenameSpace;
  final Function(Space) onDeleteSpace;
  final Function(TableModel) onEditTable;
  final Function(TableModel) onDeleteTable;

  const SetupMapTab({
    super.key,
    required this.spaces,
    required this.tables,
    required this.onRenameSpace,
    required this.onDeleteSpace,
    required this.onEditTable,
    required this.onDeleteTable,
  });

  @override
  Widget build(BuildContext context) {
    if (spaces.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.edit_location_alt,
        message: 'Πατήστε το + για να φτιάξετε Χώρους',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Διαχείριση Χώρων & Τραπεζιών',
          style: TextStyle(fontSize: 14, color: Colors.grey),
        ),
        const SizedBox(height: 8),
        for (var s in spaces)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              title: Text(s.name,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(
                '${tables.where((t) => t.spaceId == s.id).length} τραπέζια • ${s.hasBounds ? "Με Κλειδωμένα Όρια" : "Ελεύθερα Όρια"}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      final c = TextEditingController(text: s.name);
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Επεξεργασία Χώρου'),
                          content: TextField(controller: c),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Άκυρο'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                onRenameSpace(s, c.text);
                                Navigator.pop(ctx);
                              },
                              child: const Text('Αποθήκευση'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => onDeleteSpace(s),
                  ),
                ],
              ),
              children: tables
                  .where((t) => t.spaceId == s.id)
                  .map(
                    (t) => ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        backgroundColor: Color(t.colorValue),
                        radius: 12,
                      ),
                      title: Text(t.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit,
                                color: Colors.blue, size: 20),
                            onPressed: () => onEditTable(t),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete,
                                color: Colors.red, size: 20),
                            onPressed: () => onDeleteTable(t),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
      ],
    );
  }
}