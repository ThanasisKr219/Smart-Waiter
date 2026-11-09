import 'package:flutter/material.dart';

import '../../models/pos_models.dart';
import '../../theme/app_theme.dart';
import 'setup_map_tab.dart';
import 'setup_menu_tab.dart';

class SetupTab extends StatefulWidget {
  final List<Space> spaces;
  final List<TableModel> tables;
  final List<Category> menu;
  final Function(Space, String) onRenameSpace;
  final Function(Space) onDeleteSpace;
  final Function(TableModel) onEditTable;
  final Function(TableModel) onDeleteTable;
  final Function(Category, String) onRenameCategory;
  final Function(Category) onDeleteCategory;
  final Function(Product, String, double) onEditProduct;
  final Function(Category, Product) onDeleteProduct;
  final ValueChanged<int>? onModeChanged;

  const SetupTab({
    super.key,
    required this.spaces,
    required this.tables,
    required this.menu,
    required this.onRenameSpace,
    required this.onDeleteSpace,
    required this.onEditTable,
    required this.onDeleteTable,
    required this.onRenameCategory,
    required this.onDeleteCategory,
    required this.onEditProduct,
    required this.onDeleteProduct,
    this.onModeChanged,
  });

  @override
  State<SetupTab> createState() => _SetupTabState();
}

class _SetupTabState extends State<SetupTab> {
  int _selectedMode = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: SegmentedButton<int>(
            segments: const [
              ButtonSegment<int>(
                value: 0,
                icon: Icon(Icons.map_outlined),
                label: Text('Floor Plan'),
              ),
              ButtonSegment<int>(
                value: 1,
                icon: Icon(Icons.restaurant_menu_outlined),
                label: Text('Menu'),
              ),
            ],
            selected: {_selectedMode},
            onSelectionChanged: (selection) {
              final mode = selection.first;
              setState(() => _selectedMode = mode);
              widget.onModeChanged?.call(mode);
            },
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.electricCyan;
                }
                return AppColors.deepSlateNavy;
              }),
              foregroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return AppColors.midnightNavy;
                }
                return AppColors.frostWhite;
              }),
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _selectedMode,
            children: [
              SetupMapTab(
                spaces: widget.spaces,
                tables: widget.tables,
                onRenameSpace: widget.onRenameSpace,
                onDeleteSpace: widget.onDeleteSpace,
                onEditTable: widget.onEditTable,
                onDeleteTable: widget.onDeleteTable,
              ),
              SetupMenuTab(
                menu: widget.menu,
                onRenameCategory: widget.onRenameCategory,
                onDeleteCategory: widget.onDeleteCategory,
                onEditProduct: widget.onEditProduct,
                onDeleteProduct: widget.onDeleteProduct,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
