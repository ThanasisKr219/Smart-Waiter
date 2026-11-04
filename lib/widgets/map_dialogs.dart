import 'dart:math';

import 'package:flutter/material.dart';

import '../models/pos_models.dart';

Future<T?> showSmoothDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: 'Dialog',
    barrierColor: Colors.black.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 280),
    pageBuilder: (context, animation, secondaryAnimation) => builder(context),
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutBack,
      );
      return FadeTransition(
        opacity: animation,
        child: ScaleTransition(scale: curved, child: child),
      );
    },
  );
}

enum SyncStage { connecting, success, error }

class SyncProgressDialog extends StatefulWidget {
  const SyncProgressDialog({required this.onPerformSync, super.key});

  final Future<String> Function() onPerformSync;

  @override
  State<SyncProgressDialog> createState() => _SyncProgressDialogState();
}

class _SyncProgressDialogState extends State<SyncProgressDialog>
    with TickerProviderStateMixin {
  late final AnimationController _radarController;
  late final AnimationController _shakeController;
  SyncStage _stage = SyncStage.connecting;
  String? _message;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _startSync();
  }

  @override
  void dispose() {
    _radarController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  Future<void> _startSync() async {
    if (mounted) {
      setState(() {
        _stage = SyncStage.connecting;
        _message = null;
      });
    }
    try {
      final summary = await widget.onPerformSync();
      if (!mounted) return;
      setState(() {
        _stage = SyncStage.success;
        _message = summary;
      });
      await Future.delayed(const Duration(milliseconds: 1400));
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _stage = SyncStage.error;
        _message = error.toString().replaceFirst('Exception: ', '');
      });
      _shakeController.forward(from: 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: ScaleTransition(scale: animation, child: child),
          ),
          child: _buildStage(),
        ),
      ),
    );
  }

  Widget _buildStage() {
    switch (_stage) {
      case SyncStage.connecting:
        return _ConnectingView(
          key: const ValueKey(SyncStage.connecting),
          controller: _radarController,
        );
      case SyncStage.success:
        return _ResultView(
          key: const ValueKey(SyncStage.success),
          icon: Icons.check_rounded,
          color: Colors.green,
          title: 'Sync complete',
          message: _message!,
        );
      case SyncStage.error:
        return AnimatedBuilder(
          key: const ValueKey(SyncStage.error),
          animation: _shakeController,
          builder: (context, child) => Transform.translate(
            offset: Offset(sin(_shakeController.value * pi * 6) * 8, 0),
            child: child,
          ),
          child: _ErrorView(
            message: _message ?? 'Connection error.',
            onCancel: () => Navigator.of(context).pop(false),
            onRetry: _startSync,
          ),
        );
    }
  }
}

class _ConnectingView extends StatelessWidget {
  const _ConnectingView({required this.controller, super.key});

  final Animation<double> controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) => SizedBox(
        width: 250,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (final scale in [0.55, 0.78, 1.0])
                    Transform.scale(
                      scale: 0.7 + (controller.value * 0.3),
                      child: Container(
                        width: 110 * scale,
                        height: 110 * scale,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.blue.withValues(
                              alpha: (1 - controller.value) * 0.35,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blue,
                    child: Icon(
                      Icons.wifi_tethering,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Synchronizing with Host...',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResultView extends StatelessWidget {
  const _ResultView({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    super.key,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 34,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 42),
          ),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onCancel,
    required this.onRetry,
  });

  final String message;
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 250,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircleAvatar(
            radius: 34,
            backgroundColor: Colors.red,
            child: Icon(
              Icons.error_outline_rounded,
              color: Colors.white,
              size: 42,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sync failed',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(onPressed: onCancel, child: const Text('Cancel')),
              ElevatedButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ],
      ),
    );
  }
}

class MapDialogs {
  static void showTransferOrMergeDialog({
    required BuildContext context,
    required TableModel sourceTable,
    required TableModel targetTable,
    required TableModel masterSource,
    required TableModel masterTarget,
    required bool hasSourceOrder,
    required VoidCallback onUnmergeGroup,
    required VoidCallback onTransferOrder,
    required VoidCallback onMergeTables,
  }) {
    if (masterSource.id == masterTarget.id) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Merged Tables'),
          content: Text(
            'Tables "${sourceTable.name}" and "${targetTable.name}" are already merged. Would you like to unmerge them?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.link_off),
              label: const Text('Unmerge All'),
              onPressed: () {
                onUnmergeGroup();
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tables unmerged.')),
                );
              },
            ),
          ],
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.compare_arrows, color: Colors.blueGrey),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '${sourceTable.name} ➔ ${targetTable.name}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select an action:',
              style: TextStyle(color: Colors.black54, fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                disabledForegroundColor: Colors.grey.shade600,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.drive_file_move_outline),
              label: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '1. Transfer Order',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    hasSourceOrder
                        ? 'Transfers products to ${masterTarget.name} and clears ${masterSource.name}'
                        : 'Unavailable (${masterSource.name} has no order)',
                    style: TextStyle(
                      fontSize: 11,
                      color: hasSourceOrder
                          ? Colors.white70
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
              onPressed: !hasSourceOrder
                  ? null
                  : () {
                      onTransferOrder();
                      Navigator.pop(ctx);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Order transferred: ${masterSource.name} ➔ ${masterTarget.name}',
                          ),
                        ),
                      );
                    },
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  vertical: 14,
                  horizontal: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.link),
              label: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '2. Merge Tables',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    'Merges the tables and their orders into one',
                    style: TextStyle(fontSize: 11, color: Colors.white70),
                  ),
                ],
              ),
              onPressed: () {
                onMergeTables();
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  static void showEditTableDialog({
    required BuildContext context,
    required TableModel table,
    required VoidCallback onDelete,
    required void Function(String newName, double newScale, int newColor)
    onSave,
  }) {
    final nameC = TextEditingController(text: table.name);
    double tempScale = table.scale;
    int tempColor = table.colorValue;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSubState) {
          return AlertDialog(
            title: const Text('Edit Table'),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameC,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Size:'),
                  SegmentedButton<double>(
                    segments: const [
                      ButtonSegment(value: 0.8, label: Text('Small')),
                      ButtonSegment(value: 1.0, label: Text('Normal')),
                      ButtonSegment(value: 1.3, label: Text('Large')),
                    ],
                    selected: {tempScale},
                    onSelectionChanged: (val) =>
                        setSubState(() => tempScale = val.first),
                  ),
                  const SizedBox(height: 12),
                  const Text('Color:'),
                  Wrap(
                    spacing: 8,
                    children:
                        [
                          0xFF34495E,
                          0xFFE74C3C,
                          0xFF2ECC71,
                          0xFF3498DB,
                          0xFFF1C40F,
                          0xFF9B59B6,
                          0xFF000000,
                        ].map((col) {
                          return GestureDetector(
                            onTap: () => setSubState(() => tempColor = col),
                            child: CircleAvatar(
                              backgroundColor: Color(col),
                              radius: 15,
                              child: tempColor == col
                                  ? const Icon(
                                      Icons.check,
                                      size: 16,
                                      color: Colors.white,
                                    )
                                  : null,
                            ),
                          );
                        }).toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  onDelete();
                  Navigator.pop(ctx);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  onSave(nameC.text, tempScale, tempColor);
                  Navigator.pop(ctx);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  static void showMapAddSheet({
    required BuildContext context,
    required List<Space> spaces,
    required TextEditingController spaceNameCtrl,
    required TextEditingController tableNameCtrl,
    required String? initialSelectedSpace,
    required int initialSelectedColor,
    required void Function(String?) onSpaceChanged,
    required void Function(int) onColorChanged,
    required void Function(String spaceName) onAddSpace,
    required void Function(String spaceId, String tableName, int colorValue)
    onAddTable,
  }) {
    String? currentSpace = initialSelectedSpace;
    int currentColor = initialSelectedColor;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add to Floor Plan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: spaceNameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'New Space',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (spaceNameCtrl.text.isNotEmpty) {
                        onAddSpace(spaceNameCtrl.text);
                        spaceNameCtrl.clear();
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Space'),
                  ),
                ],
              ),
              const Divider(height: 30),
              if (spaces.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: currentSpace,
                  items: spaces
                      .map(
                        (s) =>
                            DropdownMenuItem(value: s.id, child: Text(s.name)),
                      )
                      .toList(),
                  onChanged: (v) {
                    currentSpace = v;
                    onSpaceChanged(v);
                    setModalState(() {});
                  },
                  decoration: const InputDecoration(
                    labelText: 'Select Space',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: tableNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Table Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children:
                      [
                        0xFF34495E,
                        0xFFE74C3C,
                        0xFF2ECC71,
                        0xFF3498DB,
                        0xFFF1C40F,
                        0xFF9B59B6,
                        0xFF000000,
                      ].map((col) {
                        return GestureDetector(
                          onTap: () {
                            currentColor = col;
                            onColorChanged(col);
                            setModalState(() {});
                          },
                          child: CircleAvatar(
                            backgroundColor: Color(col),
                            radius: 16,
                            child: currentColor == col
                                ? const Icon(
                                    Icons.check,
                                    size: 16,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                        );
                      }).toList(),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      if (currentSpace == null) return;
                      onAddTable(
                        currentSpace!,
                        tableNameCtrl.text,
                        currentColor,
                      );
                      tableNameCtrl.clear();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Add Table'),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  static void showMenuAddSheet({
    required BuildContext context,
    required List<Category> menu,
    required TextEditingController catNameCtrl,
    required TextEditingController prodNameCtrl,
    required TextEditingController prodPriceCtrl,
    required String? initialSelectedCat,
    required void Function(String?) onCatChanged,
    required void Function(String catName) onAddCategory,
    required void Function(String catId, String prodName, double price)
    onAddProduct,
  }) {
    String? currentCat = initialSelectedCat;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add to Menu',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: catNameCtrl,
                      decoration: const InputDecoration(
                        hintText: 'New Category',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      if (catNameCtrl.text.isNotEmpty) {
                        onAddCategory(catNameCtrl.text);
                        catNameCtrl.clear();
                        Navigator.pop(ctx);
                      }
                    },
                    child: const Text('Category'),
                  ),
                ],
              ),
              const Divider(height: 30),
              if (menu.isNotEmpty) ...[
                DropdownButtonFormField<String>(
                  value: currentCat,
                  items: menu
                      .map(
                        (c) =>
                            DropdownMenuItem(value: c.id, child: Text(c.name)),
                      )
                      .toList(),
                  onChanged: (v) {
                    currentCat = v;
                    onCatChanged(v);
                    setModalState(() {});
                  },
                  decoration: const InputDecoration(
                    labelText: 'Select Category',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: prodNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Product Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: prodPriceCtrl,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: const InputDecoration(
                    labelText: 'Price (€)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () {
                      if (currentCat == null || prodNameCtrl.text.isEmpty) {
                        return;
                      }
                      final double parsedPrice = max(
                        0.0,
                        double.tryParse(
                              prodPriceCtrl.text.replaceAll(',', '.'),
                            ) ??
                            0.0,
                      );
                      onAddProduct(currentCat!, prodNameCtrl.text, parsedPrice);
                      prodNameCtrl.clear();
                      prodPriceCtrl.clear();
                      Navigator.pop(ctx);
                    },
                    child: const Text('Add Product'),
                  ),
                ),
              ],
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
