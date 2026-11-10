import 'package:flutter/material.dart';

import '../../models/pos_models.dart';
import '../../widgets/empty_state_widget.dart';
import '../../theme/app_theme.dart';

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
        message: 'Press + to create spaces',
      );
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Manage Spaces & Tables',
          style: TextStyle(fontSize: 14, color: AppColors.steelGrey),
        ),
        const SizedBox(height: 8),
        for (var s in spaces)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ExpansionTile(
              title: Text(
                s.name,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                '${tables.where((t) => t.spaceId == s.id).length} tables • ${s.hasBounds ? "Locked Bounds" : "Free Bounds"}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: AppColors.electricCyan),
                    onPressed: () {
                      final c = TextEditingController(text: s.name);
                      showDialog(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Edit Space'),
                          content: TextField(controller: c),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel'),
                            ),
                            ElevatedButton(
                              onPressed: () {
                                onRenameSpace(s, c.text);
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
                    icon: const Icon(Icons.delete, color: AppColors.coralRed),
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
                        backgroundColor: AppColors.deepSlateNavy,
                        radius: 12,
                      ),
                      title: Text(t.name),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.edit,
                              color: AppColors.electricCyan,
                              size: 20,
                            ),
                            onPressed: () => onEditTable(t),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.delete,
                              color: AppColors.coralRed,
                              size: 20,
                            ),
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
