import 'dart:math';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../models/pos_models.dart';
import '../services/storage_service.dart';
import '../services/wifi_sync_service.dart';
import '../theme/app_theme.dart';
import '../widgets/map_dialogs.dart';
import 'order_screen.dart';
import 'pos_tabs.dart';

class MainScreen extends StatefulWidget {
  final AppStorageData? initialData;

  const MainScreen({super.key, required this.initialData});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  static const double virtualCanvasWidth = 2400.0;
  static const double virtualCanvasHeight = 2400.0;
  static const double minBoundSize = 260.0;

  int _currentIndex = 0;
  int _setupMode = 0;
  List<Space> spaces = [];
  List<TableModel> tables = [];
  List<Category> menu = [];
  Map<String, TableOrder> orders = {};
  List<OrderTicket> pendingTickets = [];

  double shiftTotal = 0.0;
  int shiftTransactionsCount = 0;
  int shiftClosedTables = 0;
  int shiftTotalItems = 0;
  List<ShiftTransaction> shiftLog = [];
  String generalNotes = '';

  late TextEditingController _notepadCtrl;
  late TextEditingController _spaceNameCtrl;
  late TextEditingController _tableNameCtrl;
  late TextEditingController _catNameCtrl;
  late TextEditingController _prodNameCtrl;
  late TextEditingController _prodPriceCtrl;
  late TransformationController _mapTransformCtrl;

  String? activeSpaceId;
  String? setupSelectedSpace;
  String? setupSelectedCat;
  int setupSelectedColor = 0xFF34495E;

  bool isMapEditMode = false;
  bool isSettingBoundsMode = false;
  bool isBoundsLocked = true;

  double _tempBoundLeft = 100.0;
  double _tempBoundTop = 100.0;
  double _tempBoundWidth = 900.0;
  double _tempBoundHeight = 1100.0;

  Size _lastViewportSize = const Size(400, 600);

  final uuid = const Uuid();
  final WifiSyncService _wifiSyncService = WifiSyncService();

  @override
  void initState() {
    super.initState();
    _notepadCtrl = TextEditingController();
    _spaceNameCtrl = TextEditingController();
    _tableNameCtrl = TextEditingController();
    _catNameCtrl = TextEditingController();
    _prodNameCtrl = TextEditingController();
    _prodPriceCtrl = TextEditingController();
    _mapTransformCtrl = TransformationController();
    _initializeData();
  }

  @override
  void dispose() {
    _notepadCtrl.dispose();
    _spaceNameCtrl.dispose();
    _tableNameCtrl.dispose();
    _catNameCtrl.dispose();
    _prodNameCtrl.dispose();
    _prodPriceCtrl.dispose();
    _mapTransformCtrl.dispose();
    _wifiSyncService.dispose();
    super.dispose();
  }

  Space? get _activeSpace {
    if (spaces.isEmpty || activeSpaceId == null) return null;
    final idx = spaces.indexWhere((s) => s.id == activeSpaceId);
    return idx == -1 ? null : spaces[idx];
  }

  // --- MAP BOUNDS (CUSTOM BORDERS & CAMERA LOCK) ---

  Rect _calculateAutoBoundsForSpace(String spaceId) {
    final spaceTables = tables.where((t) => t.spaceId == spaceId).toList();
    if (spaceTables.isEmpty) {
      return const Rect.fromLTWH(80.0, 80.0, 900.0, 1100.0);
    }

    double minX = virtualCanvasWidth;
    double minY = virtualCanvasHeight;
    double maxX = 0.0;
    double maxY = 0.0;

    for (final t in spaceTables) {
      final double diameter = 76.0 * t.scale;
      if (t.left < minX) minX = t.left;
      if (t.top < minY) minY = t.top;
      if (t.left + diameter > maxX) maxX = t.left + diameter;
      if (t.top + diameter > maxY) maxY = t.top + diameter;
    }

    const double padding = 70.0;
    double width = max(maxX - minX + padding * 2, minBoundSize);
    double height = max(maxY - minY + padding * 2, minBoundSize);

    final double centerX = (minX + maxX) / 2.0;
    final double centerY = (minY + maxY) / 2.0;

    double left =
        (centerX - width / 2.0).clamp(0.0, virtualCanvasWidth - width);
    double top =
        (centerY - height / 2.0).clamp(0.0, virtualCanvasHeight - height);

    return Rect.fromLTWH(left, top, width, height);
  }

  void _focusFreeCameraOnRect(Rect targetRect, {double margin = 120.0}) {
    final double vw =
        _lastViewportSize.width <= 0 ? 400.0 : _lastViewportSize.width;
    final double vh =
        _lastViewportSize.height <= 0 ? 600.0 : _lastViewportSize.height;

    final double paddedW =
        (targetRect.width + margin * 2).clamp(200.0, virtualCanvasWidth);
    final double paddedH =
        (targetRect.height + margin * 2).clamp(200.0, virtualCanvasHeight);

    final double scale = min(vw / paddedW, vh / paddedH).clamp(0.2, 2.0);
    final double tx = (vw / 2.0) - (targetRect.center.dx * scale);
    final double ty = (vh / 2.0) - (targetRect.center.dy * scale);

    _mapTransformCtrl.value = Matrix4.identity()
      ..translateByDouble(tx, ty, 0.0, 1.0)
      ..scaleByDouble(scale, scale, scale, 1.0);
  }

  void _enterSetBoundsMode() {
    final space = _activeSpace;
    if (space == null) return;

    setState(() {
      isSettingBoundsMode = true;
      isMapEditMode = false;

      if (space.hasBounds) {
        _tempBoundLeft = space.boundLeft!;
        _tempBoundTop = space.boundTop!;
        _tempBoundWidth = space.boundWidth!;
        _tempBoundHeight = space.boundHeight!;
      } else {
        final autoRect = _calculateAutoBoundsForSpace(space.id);
        _tempBoundLeft = autoRect.left;
        _tempBoundTop = autoRect.top;
        _tempBoundWidth = autoRect.width;
        _tempBoundHeight = autoRect.height;
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _focusFreeCameraOnRect(
          Rect.fromLTWH(
              _tempBoundLeft, _tempBoundTop, _tempBoundWidth, _tempBoundHeight),
          margin: 180.0,
        );
      });
    });
  }

  void _saveBoundsForActiveSpace() {
    final space = _activeSpace;
    if (space == null) return;

    setState(() {
      space.boundLeft = _tempBoundLeft;
      space.boundTop = _tempBoundTop;
      space.boundWidth = _tempBoundWidth;
      space.boundHeight = _tempBoundHeight;
      isSettingBoundsMode = false;
      isBoundsLocked = true;
      _mapTransformCtrl.value = Matrix4.identity();
    });
    _saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Bounds saved and the camera is locked to the space!'),
        backgroundColor: AppColors.emerald,
      ),
    );
  }

  void _clearBoundsForActiveSpace() {
    final space = _activeSpace;
    if (space == null) return;

    setState(() {
      space.boundLeft = null;
      space.boundTop = null;
      space.boundWidth = null;
      space.boundHeight = null;
      isSettingBoundsMode = false;
      isBoundsLocked = false;
      _mapTransformCtrl.value = Matrix4.identity();
    });
    _saveData();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Space bounds removed.')),
    );
  }

  void _toggleFocusLockButton() {
    final space = _activeSpace;
    if (space == null) return;

    if (isSettingBoundsMode) {
      _saveBoundsForActiveSpace();
      return;
    }

    if (!space.hasBounds) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Drag the corners to set the space bounds and press Save!'),
          duration: Duration(seconds: 3),
        ),
      );
      _enterSetBoundsMode();
      return;
    }

    setState(() {
      isBoundsLocked = !isBoundsLocked;
      _mapTransformCtrl.value = Matrix4.identity();
    });

    if (!isBoundsLocked) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _focusFreeCameraOnRect(
            Rect.fromLTWH(
              space.boundLeft!,
              space.boundTop!,
              space.boundWidth!,
              space.boundHeight!,
            ),
            margin: 150.0,
          );
        });
      });
    }
  }

  // --- MERGED TABLES & DATA SAFETY ---

  TableModel _getMasterTable(TableModel t) {
    if (t.masterTableId == null) return t;
    final idx = tables.indexWhere((x) => x.id == t.masterTableId);
    if (idx == -1) {
      t.masterTableId = null;
      return t;
    }
    return tables[idx];
  }

  List<TableModel> _getMergedGroup(TableModel table) {
    final master = _getMasterTable(table);
    return tables
        .where((t) =>
            t.spaceId == master.spaceId &&
            (t.id == master.id || t.masterTableId == master.id))
        .toList();
  }

  void _sanitizeMergedTables() {
    for (var t in tables) {
      if (t.masterTableId != null) {
        final masterIdx = tables.indexWhere((m) => m.id == t.masterTableId);
        if (masterIdx == -1 || tables[masterIdx].spaceId != t.spaceId) {
          t.masterTableId = null;
        } else if (tables[masterIdx].masterTableId != null) {
          t.masterTableId = tables[masterIdx].masterTableId;
        }
      }
    }
    orders.removeWhere((tableId, _) => !tables.any((t) => t.id == tableId));
  }

  void _deleteTableSafe(TableModel table) {
    setState(() {
      if (table.masterTableId == null) {
        final slaves =
            tables.where((t) => t.masterTableId == table.id).toList();
        if (slaves.isNotEmpty) {
          final newMaster = slaves.first;
          newMaster.masterTableId = null;
          if (orders.containsKey(table.id)) {
            orders[newMaster.id] = orders[table.id]!;
          }
          for (int i = 1; i < slaves.length; i++) {
            slaves[i].masterTableId = newMaster.id;
          }
        }
      }
      tables.removeWhere((t) => t.id == table.id);
      orders.remove(table.id);
      _sanitizeMergedTables();
    });
    _saveData();
  }

  void _unmergeGroup(TableModel masterTable) {
    setState(() {
      for (var t in tables) {
        if (t.masterTableId == masterTable.id) {
          t.masterTableId = null;
        }
      }
    });
    _saveData();
  }

  void _unmergeSingleTable(TableModel tableToDetach) {
    setState(() {
      tableToDetach.masterTableId = null;
    });
    _saveData();
  }

  // --- LOADING & SAVING ---

  void _initializeData() {
    final loaded = widget.initialData;
    if (loaded == null) {
      final firstSpace = Space(id: uuid.v4(), name: 'Main Area');
      spaces.add(firstSpace);
      activeSpaceId = firstSpace.id;
      setupSelectedSpace = firstSpace.id;
      isBoundsLocked = false;
      _saveData();
      return;
    }

    spaces = loaded.spaces;
    tables = loaded.tables;
    menu = loaded.menu;
    orders = loaded.orders;
    pendingTickets = loaded.pendingTickets;
    shiftTotal = loaded.shiftTotal;
    shiftTransactionsCount = loaded.shiftTransactionsCount;
    shiftClosedTables = loaded.shiftClosedTables;
    shiftTotalItems = loaded.shiftTotalItems;
    shiftLog = loaded.shiftLog;
    generalNotes = loaded.generalNotes;
    _notepadCtrl.text = generalNotes;

    _sanitizeMergedTables();

    if (spaces.isNotEmpty) {
      activeSpaceId = spaces.first.id;
      setupSelectedSpace = spaces.first.id;
    }
    if (menu.isNotEmpty) {
      setupSelectedCat = menu.first.id;
    }
    isBoundsLocked = _activeSpace?.hasBounds ?? false;
  }

  Future<void> _saveData() async {
    await StorageService.saveData(
      spaces: spaces,
      tables: tables,
      menu: menu,
      orders: orders,
      pendingTickets: pendingTickets,
      shiftTotal: shiftTotal,
      shiftTransactionsCount: shiftTransactionsCount,
      shiftClosedTables: shiftClosedTables,
      shiftTotalItems: shiftTotalItems,
      shiftLog: shiftLog,
      generalNotes: generalNotes,
    );
  }

  // --- MAP & ORDER ACTIONS ---

  void _addPendingTicket(OrderTicket ticket) {
    setState(() => pendingTickets.add(ticket));
    _saveData();
  }

  void _confirmPendingTicket(OrderTicket ticket) {
    final target = tables.where((table) => table.id == ticket.tableId).firstOrNull;
    if (target == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('The ticket table no longer exists.')),
      );
      return;
    }
    final master = _getMasterTable(target);
    setState(() {
      final order = orders.putIfAbsent(master.id, () => TableOrder(items: []));
      for (final item in ticket.items) {
        order.addOrGroupItem(item);
      }
      if (ticket.tableNote.trim().isNotEmpty) {
        order.note = order.note.isEmpty
            ? ticket.tableNote
            : '${order.note} | ${ticket.tableNote}';
      }
      pendingTickets.removeWhere((pending) => pending.id == ticket.id);
    });
    _saveData();
  }

  void _rejectPendingTicket(OrderTicket ticket) {
    setState(() => pendingTickets.removeWhere((pending) => pending.id == ticket.id));
    _saveData();
  }

  void _updatePendingTicket(OrderTicket ticket) {
    if (ticket.items.isEmpty) {
      _rejectPendingTicket(ticket);
      return;
    }
    setState(() {});
    _saveData();
  }

  bool _checkCollision(
      String tableId, double left, double top, double scale, String spaceId) {
    double r1 = 38.0 * scale;
    double c1X = left + r1;
    double c1Y = top + r1;

    for (var t
        in tables.where((tbl) => tbl.spaceId == spaceId && tbl.id != tableId)) {
      double r2 = 38.0 * t.scale;
      double c2X = t.left + r2;
      double c2Y = t.top + r2;

      double distSq = (c1X - c2X) * (c1X - c2X) + (c1Y - c2Y) * (c1Y - c2Y);
      double minRadSq = (r1 + r2 + 4) * (r1 + r2 + 4);

      if (distSq < minRadSq) return true;
    }
    return false;
  }

  void _handleTransferOrMerge(TableModel sourceTable, TableModel targetTable) {
    final masterSource = _getMasterTable(sourceTable);
    final masterTarget = _getMasterTable(targetTable);
    final sourceOrder = orders[masterSource.id];
    final hasSourceOrder = sourceOrder != null && sourceOrder.items.isNotEmpty;

    MapDialogs.showTransferOrMergeDialog(
      context: context,
      sourceTable: sourceTable,
      targetTable: targetTable,
      masterSource: masterSource,
      masterTarget: masterTarget,
      hasSourceOrder: hasSourceOrder,
      onUnmergeGroup: () => _unmergeGroup(masterSource),
      onTransferOrder: () {
        setState(() {
          if (!orders.containsKey(masterTarget.id)) {
            orders[masterTarget.id] = TableOrder(items: []);
          }
          final targetOrder = orders[masterTarget.id]!;
          for (var item in sourceOrder!.items) {
            targetOrder.addOrGroupItem(item);
          }
          if (sourceOrder.note.isNotEmpty) {
            targetOrder.note = targetOrder.note.isEmpty
                ? sourceOrder.note
                : '${targetOrder.note} | ${sourceOrder.note}';
          }
          sourceOrder.items.clear();
          sourceOrder.note = '';
          for (final ticket in pendingTickets) {
            if (ticket.tableId == sourceTable.id ||
                ticket.tableId == masterSource.id) {
              ticket.tableId = masterTarget.id;
              ticket.tableName = masterTarget.name;
            }
          }
        });
        _saveData();
      },
      onMergeTables: () {
        setState(() {
          if (!orders.containsKey(masterTarget.id)) {
            orders[masterTarget.id] = TableOrder(items: []);
          }
          final targetOrder = orders[masterTarget.id]!;

          if (sourceOrder != null && sourceOrder.items.isNotEmpty) {
            for (var item in sourceOrder.items) {
              targetOrder.addOrGroupItem(item);
            }
            if (sourceOrder.note.isNotEmpty) {
              targetOrder.note = targetOrder.note.isEmpty
                  ? sourceOrder.note
                  : '${targetOrder.note} | ${sourceOrder.note}';
            }
            sourceOrder.items.clear();
            sourceOrder.note = '';
          }

          for (var t in tables) {
            if (t.id == masterSource.id || t.masterTableId == masterSource.id) {
              t.masterTableId = masterTarget.id;
            }
          }
          masterTarget.masterTableId = null;
          for (final ticket in pendingTickets) {
            if (ticket.tableId == sourceTable.id ||
                ticket.tableId == masterSource.id) {
              ticket.tableId = masterTarget.id;
              ticket.tableName = masterTarget.name;
            }
          }
        });
        _saveData();
        final groupNames =
            _getMergedGroup(masterTarget).map((e) => e.name).join(' + ');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Merged: $groupNames'),
            backgroundColor: AppColors.emerald,
          ),
        );
      },
    );
  }

  void _openEditTableDialog(TableModel table) {
    MapDialogs.showEditTableDialog(
      context: context,
      table: table,
      onDelete: () => _deleteTableSafe(table),
      onSave: (newName, newScale, newColor) {
        setState(() {
          table.name = newName;
          table.scale = newScale;
          table.colorValue = newColor;
          final double maxCoordX = virtualCanvasWidth - (76.0 * newScale);
          final double maxCoordY = virtualCanvasHeight - (76.0 * newScale);
          table.left = table.left.clamp(8.0, maxCoordX);
          table.top = table.top.clamp(8.0, maxCoordY);
        });
        _saveData();
      },
    );
  }

  void _openOrderScreen(TableModel tappedTable, {OrderTicket? editingTicket}) {
    final TableModel masterTable = _getMasterTable(tappedTable);
    if (!orders.containsKey(masterTable.id)) {
      orders[masterTable.id] = TableOrder(items: []);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OrderScreen(
          masterTable: masterTable,
          getMergedGroup: () => _getMergedGroup(masterTable),
          onUnmergeAll: () => _unmergeGroup(masterTable),
          onUnmergeSingle: (TableModel slave) => _unmergeSingleTable(slave),
          menu: menu,
          order: orders[masterTable.id]!,
          pendingTickets: pendingTickets
              .where((ticket) => ticket.tableId == masterTable.id)
              .toList(),
          editingTicket: editingTicket,
          hasPendingTickets: () => pendingTickets.any(
              (ticket) => ticket.tableId == masterTable.id),
          onSendOrder: (items) {
            _addPendingTicket(
              OrderTicket(
                id: uuid.v4(),
                tableId: masterTable.id,
                tableName: _getMergedGroup(masterTable)
                    .map((table) => table.name)
                    .join(' + '),
                tableNote: orders[masterTable.id]!.note,
                timestamp: DateTime.now(),
                items: items,
              ),
            );
          },
          onPendingTicketChanged: _updatePendingTicket,
          onPendingTicketRemoved: (id) {
            setState(() => pendingTickets.removeWhere((ticket) => ticket.id == id));
            _saveData();
          },
          onOrderChanged: (bool isPaid, double paidAmount, bool isFullPayment,
              List<OrderItem> paidItems) {
            setState(() {
              if (isPaid) {
                final mergedGroup = _getMergedGroup(masterTable);
                final String displayTableName =
                    mergedGroup.map((t) => t.name).join(' + ');

                shiftTotal += paidAmount;
                shiftTransactionsCount += 1;

                final int countItems =
                    paidItems.fold(0, (sum, item) => sum + item.quantity);
                shiftTotalItems += countItems;

                if (isFullPayment) {
                  shiftClosedTables += mergedGroup.length;
                  for (var t in mergedGroup) {
                    t.masterTableId = null;
                  }
                }

                shiftLog.insert(
                  0,
                  ShiftTransaction(
                    id: uuid.v4(),
                    time: DateTime.now(),
                    tableName: displayTableName,
                    type: isFullPayment ? 'Full' : 'Partial',
                    amount: paidAmount,
                    items: paidItems,
                  ),
                );
              }
            });
            _saveData();
          },
        ),
      ),
    ).then((_) {
      setState(() {});
      _saveData();
    });
  }

  void _openMapAddSheet() {
    if (spaces.isNotEmpty &&
        (setupSelectedSpace == null ||
            !spaces.any((s) => s.id == setupSelectedSpace))) {
      setupSelectedSpace = spaces.first.id;
    }

    MapDialogs.showMapAddSheet(
      context: context,
      spaces: spaces,
      spaceNameCtrl: _spaceNameCtrl,
      tableNameCtrl: _tableNameCtrl,
      initialSelectedSpace: setupSelectedSpace,
      initialSelectedColor: setupSelectedColor,
      onSpaceChanged: (v) => setState(() => setupSelectedSpace = v),
      onColorChanged: (col) => setState(() => setupSelectedColor = col),
      onAddSpace: (spaceName) {
        setState(() {
          spaces.add(Space(id: uuid.v4(), name: spaceName));
          activeSpaceId ??= spaces.last.id;
          setupSelectedSpace = spaces.last.id;
        });
        _saveData();
      },
      onAddTable: (spaceId, rawTableName, colorVal) {
        final targetSpace = spaces.firstWhere((s) => s.id == spaceId);

        final double startX =
            targetSpace.hasBounds ? targetSpace.boundLeft! + 20.0 : 30.0;
        final double startY =
            targetSpace.hasBounds ? targetSpace.boundTop! + 20.0 : 30.0;
        final double limitX = targetSpace.hasBounds
            ? (targetSpace.boundLeft! + targetSpace.boundWidth! - 85.0)
            : 750.0;

        double spawnX = startX;
        double spawnY = startY;

        while (_checkCollision('temp', spawnX, spawnY, 1.0, spaceId)) {
          spawnX += 86.0;
          if (spawnX > limitX) {
            spawnX = startX;
            spawnY += 86.0;
          }
        }

        final int countInSpace =
            tables.where((t) => t.spaceId == spaceId).length + 1;

        setState(() {
          tables.add(
            TableModel(
              id: uuid.v4(),
              name: rawTableName.trim().isEmpty
                  ? 'T$countInSpace'
                  : rawTableName.trim(),
              colorValue: colorVal,
              top: spawnY.clamp(8.0, virtualCanvasHeight - 80.0),
              left: spawnX.clamp(8.0, virtualCanvasWidth - 80.0),
              spaceId: spaceId,
            ),
          );
        });
        _saveData();
      },
    );
  }

  void _openMenuAddSheet() {
    if (menu.isNotEmpty &&
        (setupSelectedCat == null ||
            !menu.any((c) => c.id == setupSelectedCat))) {
      setupSelectedCat = menu.first.id;
    }

    MapDialogs.showMenuAddSheet(
      context: context,
      menu: menu,
      catNameCtrl: _catNameCtrl,
      prodNameCtrl: _prodNameCtrl,
      prodPriceCtrl: _prodPriceCtrl,
      initialSelectedCat: setupSelectedCat,
      onCatChanged: (v) => setState(() => setupSelectedCat = v),
      onAddCategory: (catName) {
        setState(() {
          menu.add(Category(id: uuid.v4(), name: catName, items: []));
          setupSelectedCat = menu.last.id;
        });
        _saveData();
      },
      onAddProduct: (catId, prodName, price) {
        setState(() {
          menu.firstWhere((c) => c.id == catId).items.add(
                Product(id: uuid.v4(), name: prodName, price: price),
              );
        });
        _saveData();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final Space? currentSpace = _activeSpace;
    final currentTables = currentSpace == null
        ? <TableModel>[]
        : tables.where((t) => t.spaceId == currentSpace.id).toList();

    final pages = [
      FloorPlanTab(
        virtualCanvasWidth: virtualCanvasWidth,
        virtualCanvasHeight: virtualCanvasHeight,
        minBoundSize: minBoundSize,
        spaces: spaces,
        activeSpace: currentSpace,
        currentTables: currentTables,
        orders: orders,
        mapTransformCtrl: _mapTransformCtrl,
        isMapEditMode: isMapEditMode,
        isSettingBoundsMode: isSettingBoundsMode,
        isBoundsLocked: isBoundsLocked,
        tempBounds: Rect.fromLTWH(
            _tempBoundLeft, _tempBoundTop, _tempBoundWidth, _tempBoundHeight),
        onSelectSpace: (sp) {
          setState(() {
            activeSpaceId = sp.id;
            isSettingBoundsMode = false;
            isBoundsLocked = sp.hasBounds;
            _mapTransformCtrl.value = Matrix4.identity();
          });
        },
        onAutoBoundsRequested: () {
          if (currentSpace == null) return;
          final autoR = _calculateAutoBoundsForSpace(currentSpace.id);
          setState(() {
            _tempBoundLeft = autoR.left;
            _tempBoundTop = autoR.top;
            _tempBoundWidth = autoR.width;
            _tempBoundHeight = autoR.height;
            _focusFreeCameraOnRect(autoR, margin: 160.0);
          });
        },
        onClearBoundsRequested: _clearBoundsForActiveSpace,
        onSaveBoundsRequested: _saveBoundsForActiveSpace,
        onViewportSizeReported: (size) => _lastViewportSize = size,
        onViewerInteractionUpdate: () {
          if (isSettingBoundsMode) setState(() {});
        },
        getMasterTable: _getMasterTable,
        getMergedGroup: _getMergedGroup,
        checkCollision: (tableId, left, top, scale) =>
            _checkCollision(tableId, left, top, scale, activeSpaceId!),
        onTableMoved: (table, newLeft, newTop) {
          setState(() {
            table.left = newLeft;
            table.top = newTop;
          });
        },
        onTableMoveEnded: _saveData,
        onEditTable: _openEditTableDialog,
        onOpenOrder: _openOrderScreen,
        onTransferOrMergeRequested: _handleTransferOrMerge,
        onTempBoundsChanged: (rect) {
          setState(() {
            _tempBoundLeft = rect.left;
            _tempBoundTop = rect.top;
            _tempBoundWidth = rect.width;
            _tempBoundHeight = rect.height;
          });
        },
      ),
      CatalogTab(menu: menu),
      PendingTicketsTab(
        tickets: pendingTickets,
        onConfirm: _confirmPendingTicket,
        onReject: _rejectPendingTicket,
        onEdit: (ticket) {
          final table = tables.where((item) => item.id == ticket.tableId).firstOrNull;
          if (table != null) {
            _openOrderScreen(table, editingTicket: ticket);
          }
        },
      ),
      SetupTab(
        spaces: spaces,
        tables: tables,
        menu: menu,
        onRenameSpace: (space, newName) {
          setState(() => space.name = newName);
          _saveData();
        },
        onDeleteSpace: (space) {
          setState(() {
            final tableIdsToRemove = tables
                .where((t) => t.spaceId == space.id)
                .map((t) => t.id)
                .toSet();
            orders.removeWhere((k, _) => tableIdsToRemove.contains(k));
            spaces.removeWhere((x) => x.id == space.id);
            tables.removeWhere((t) => t.spaceId == space.id);
          });
          if (activeSpaceId == space.id) {
            activeSpaceId = spaces.isNotEmpty ? spaces.first.id : null;
          }
          if (setupSelectedSpace == space.id) {
            setupSelectedSpace = spaces.isNotEmpty ? spaces.first.id : null;
          }
          _saveData();
        },
        onEditTable: _openEditTableDialog,
        onDeleteTable: _deleteTableSafe,
        onRenameCategory: (cat, newName) {
          setState(() => cat.name = newName);
          _saveData();
        },
        onDeleteCategory: (cat) {
          setState(() => menu.removeWhere((c) => c.id == cat.id));
          if (setupSelectedCat == cat.id) {
            setupSelectedCat = menu.isNotEmpty ? menu.first.id : null;
          }
          _saveData();
        },
        onEditProduct: (prod, newName, newPrice) {
          setState(() {
            prod.name = newName;
            prod.price = newPrice;
          });
          _saveData();
        },
        onDeleteProduct: (cat, prod) {
          setState(() => cat.items.removeWhere((item) => item.id == prod.id));
          _saveData();
        },
        onModeChanged: (mode) => setState(() => _setupMode = mode),
      ),
      ShiftTab(
        shiftTotal: shiftTotal,
        shiftTransactionsCount: shiftTransactionsCount,
        shiftClosedTables: shiftClosedTables,
        shiftTotalItems: shiftTotalItems,
        shiftLog: shiftLog,
        onResetShift: () {
          setState(() {
            shiftTotal = 0.0;
            shiftTransactionsCount = 0;
            shiftClosedTables = 0;
            shiftTotalItems = 0;
            shiftLog.clear();
          });
          _saveData();
        },
      ),
      NotepadTab(
        controller: _notepadCtrl,
        onChanged: (val) {
          generalNotes = val;
          _saveData();
        },
      ),
    ];

    final bool hasSpaceBounds = currentSpace?.hasBounds ?? false;
    final bool isCurrentlyLockedToBounds =
        hasSpaceBounds && isBoundsLocked && !isSettingBoundsMode;

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _currentIndex == 0
                ? 'Floor Plan'
                : _currentIndex == 1
                    ? 'Catalog'
                    : _currentIndex == 2
                        ? 'Pending Tickets'
                        : _currentIndex == 3
                                ? 'Setup'
                                : _currentIndex == 4
                                    ? 'Cash Register'
                                    : 'Notes',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
          ),
        ),
        actions: [
          if (_currentIndex == 0) ...[
            IconButton(
              icon: Icon(
                Icons.crop,
                color: isSettingBoundsMode
                    ? AppColors.electricCyan
                    : (hasSpaceBounds ? AppColors.emerald : AppColors.steelGrey),
                size: 24,
              ),
              tooltip: 'Set Floor Plan Bounds',
              onPressed: () {
                if (isSettingBoundsMode) {
                  setState(() => isSettingBoundsMode = false);
                } else {
                  _enterSetBoundsMode();
                }
              },
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: _toggleFocusLockButton,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  decoration: BoxDecoration(
                    color: isCurrentlyLockedToBounds
                        ? AppColors.emerald
                        : AppColors.deepSlateNavy,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isCurrentlyLockedToBounds
                          ? AppColors.emerald
                          : AppColors.steelGrey,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isCurrentlyLockedToBounds
                            ? Icons.center_focus_strong
                            : Icons.crop_free,
                        color: isCurrentlyLockedToBounds
                            ? AppColors.midnightNavy
                            : AppColors.frostWhite,
                        size: 20,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isCurrentlyLockedToBounds ? 'Locked' : 'Free',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isCurrentlyLockedToBounds
                              ? AppColors.midnightNavy
                              : AppColors.frostWhite,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                isMapEditMode ? Icons.lock_open : Icons.lock,
                color: isMapEditMode ? AppColors.coralRed : AppColors.frostWhite,
                size: 26,
              ),
              tooltip: 'Lock / Unlock Tables',
              onPressed: () {
                setState(() {
                  isSettingBoundsMode = false;
                  isMapEditMode = !isMapEditMode;
                });
              },
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(right: 8.0, left: 2.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.sync, size: 16),
              label: const Text('Sync',
                  style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.amber,
                  padding: const EdgeInsets.symmetric(horizontal: 8)),
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  builder: (ctx) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const ListTile(
                          title: Text('Wi-Fi Sync',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                        ListTile(
                          leading: const Icon(Icons.wifi_tethering,
                              color: AppColors.electricCyan),
                          title: const Text('Send (Become Server)'),
                          onTap: () {
                            Navigator.pop(ctx);
                            _wifiSyncService.startHostServer(
                              context: context,
                              getSpaces: () => spaces,
                              getTables: () => tables,
                              getMenu: () => menu,
                              getPendingTickets: () => pendingTickets,
                            );
                          },
                        ),
                        ListTile(
                          leading: const Icon(Icons.qr_code_scanner,
                              color: AppColors.emerald),
                          title: const Text('Receive (Scan QR)'),
                          onTap: () {
                            Navigator.pop(ctx);
                            _wifiSyncService.scanToSync(
                              context: context,
                              onSyncSuccess:
                                  (syncedSpaces, syncedTables, syncedMenu,
                                      syncedPendingTickets) {
                                setState(() {
                                  spaces = syncedSpaces;
                                  tables = syncedTables;
                                  menu = syncedMenu;
                                  pendingTickets = syncedPendingTickets;
                                  _sanitizeMergedTables();

                                  if (spaces.isNotEmpty) {
                                    activeSpaceId = spaces.first.id;
                                    setupSelectedSpace = spaces.first.id;
                                  }
                                  if (menu.isNotEmpty) {
                                    setupSelectedCat = menu.first.id;
                                  }

                                  isSettingBoundsMode = false;
                                  isMapEditMode = false;
                                  isBoundsLocked =
                                      _activeSpace?.hasBounds ?? false;
                                  _mapTransformCtrl.value = Matrix4.identity();
                                });
                                _saveData();
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: pages[_currentIndex],
      floatingActionButton: _currentIndex == 3
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.electricCyan,
              icon: const Icon(Icons.add, color: AppColors.midnightNavy),
              label: Text(
                _setupMode == 0 ? 'New Table / Space' : 'New Product',
                style: const TextStyle(color: AppColors.midnightNavy),
              ),
              onPressed: () {
                if (_setupMode == 0) {
                  _openMapAddSheet();
                } else {
                  _openMenuAddSheet();
                }
              },
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: [
          NavigationDestination(
              icon: Icon(Icons.map_outlined),
              selectedIcon: Icon(Icons.map),
              label: 'Floor Plan'),
          NavigationDestination(
              icon: Icon(Icons.menu_book_outlined),
              selectedIcon: Icon(Icons.menu_book),
              label: 'Catalog'),
          NavigationDestination(
              icon: Badge(
                  isLabelVisible: false, child: Icon(Icons.receipt_long)),
              selectedIcon: Badge(
                  label: Text('${pendingTickets.length}'),
                  isLabelVisible: pendingTickets.isNotEmpty,
                  child: Icon(Icons.receipt_long)),
              label: 'Pending'),
          NavigationDestination(
              icon: Icon(Icons.tune_rounded),
              selectedIcon: Icon(Icons.tune_rounded),
              label: 'Setup'),
          NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale),
              label: 'Cash Register'),
          NavigationDestination(
              icon: Icon(Icons.note_alt_outlined),
              selectedIcon: Icon(Icons.note_alt),
              label: 'Notes'),
        ],
      ),
    );
  }
}
