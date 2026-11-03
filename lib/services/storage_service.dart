import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/pos_models.dart';

class AppStorageData {
  final List<Space> spaces;
  final List<TableModel> tables;
  final List<Category> menu;
  final Map<String, TableOrder> orders;
  final double shiftTotal;
  final int shiftTransactionsCount;
  final int shiftClosedTables;
  final int shiftTotalItems;
  final List<ShiftTransaction> shiftLog;
  final String generalNotes;

  AppStorageData({
    required this.spaces,
    required this.tables,
    required this.menu,
    required this.orders,
    required this.shiftTotal,
    required this.shiftTransactionsCount,
    required this.shiftClosedTables,
    required this.shiftTotalItems,
    required this.shiftLog,
    required this.generalNotes,
  });
}

class StorageService {
  static const String _storageKey = 'pro_waiter_data';

  static Future<AppStorageData?> loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final dataStr = prefs.getString(_storageKey);
    if (dataStr == null) return null;

    try {
      final decoded = jsonDecode(dataStr);
      final spaces =
          (decoded['spaces'] as List).map((e) => Space.fromJson(e)).toList();
      final tables = (decoded['tables'] as List)
          .map((e) => TableModel.fromJson(e))
          .toList();
      final menu =
          (decoded['menu'] as List).map((e) => Category.fromJson(e)).toList();
      final rawOrders = decoded['orders'] as Map<String, dynamic>? ?? {};
      final orders =
          rawOrders.map((k, v) => MapEntry(k, TableOrder.fromJson(v)));

      final shiftTotal = (decoded['shiftTotal'] as num?)?.toDouble() ?? 0.0;
      final shiftTransactionsCount = decoded['shiftTransactionsCount'] ?? 0;
      final shiftClosedTables = decoded['shiftClosedTables'] ?? 0;
      final shiftTotalItems = decoded['shiftTotalItems'] ?? 0;

      List<ShiftTransaction> shiftLog = [];
      if (decoded['shiftLog'] != null) {
        shiftLog = (decoded['shiftLog'] as List)
            .map((e) => ShiftTransaction.fromJson(e))
            .toList();
      }

      final generalNotes = decoded['generalNotes'] ?? '';

      return AppStorageData(
        spaces: spaces,
        tables: tables,
        menu: menu,
        orders: orders,
        shiftTotal: shiftTotal,
        shiftTransactionsCount: shiftTransactionsCount,
        shiftClosedTables: shiftClosedTables,
        shiftTotalItems: shiftTotalItems,
        shiftLog: shiftLog,
        generalNotes: generalNotes,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveData({
    required List<Space> spaces,
    required List<TableModel> tables,
    required List<Category> menu,
    required Map<String, TableOrder> orders,
    required double shiftTotal,
    required int shiftTransactionsCount,
    required int shiftClosedTables,
    required int shiftTotalItems,
    required List<ShiftTransaction> shiftLog,
    required String generalNotes,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final map = {
      'spaces': spaces.map((e) => e.toJson()).toList(),
      'tables': tables.map((e) => e.toJson()).toList(),
      'menu': menu.map((e) => e.toJson()).toList(),
      'orders': orders.map((k, v) => MapEntry(k, v.toJson())),
      'shiftTotal': shiftTotal,
      'shiftTransactionsCount': shiftTransactionsCount,
      'shiftClosedTables': shiftClosedTables,
      'shiftTotalItems': shiftTotalItems,
      'shiftLog': shiftLog.map((e) => e.toJson()).toList(),
      'generalNotes': generalNotes,
    };
    await prefs.setString(_storageKey, jsonEncode(map));
  }
}