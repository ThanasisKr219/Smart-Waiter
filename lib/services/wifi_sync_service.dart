import 'dart:convert';
import 'dart:io' as io;

import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:http/http.dart' as http;

import '../models/pos_models.dart';
import '../screens/scanner_screen.dart';
import '../widgets/map_dialogs.dart';

class WifiSyncService {
  io.HttpServer? _server;

  void dispose() {
    _server?.close(force: true);
  }

  Future<void> startHostServer({
    required BuildContext context,
    required List<Space> Function() getSpaces,
    required List<TableModel> Function() getTables,
    required List<Category> Function() getMenu,
  }) async {
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Open Android to become the host.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final ip = await NetworkInfo().getWifiIP();
      if (ip == null || ip.isEmpty) throw Exception('Connect to Wi-Fi!');

      await _server?.close(force: true);
      _server = await io.HttpServer.bind(
        io.InternetAddress.anyIPv4,
        8080,
        shared: true,
      );

      _server!.listen((io.HttpRequest request) {
        request.response.headers.add('Access-Control-Allow-Origin', '*');
        request.response.headers.contentType = io.ContentType.json;
        if (request.uri.path == '/sync') {
          final map = {
            'spaces': getSpaces().map((e) => e.toJson()).toList(),
            'tables': getTables().map((e) => e.toJson()).toList(),
            'menu': getMenu().map((e) => e.toJson()).toList(),
          };
          request.response.write(jsonEncode(map));
        }
        request.response.close();
      });

      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();

      showSmoothDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Row(
            children: [
              const Expanded(child: Text('Server started!')),
              _PulsingStatusBadge(),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Scan the QR code from the other phones.\n(Spaces, floor plan bounds, tables and menu will be transferred)',
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                height: 200,
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(milliseconds: 500),
                  builder: (context, value, child) => Opacity(
                    opacity: value,
                    child: Transform.scale(
                      scale: 0.9 + value * 0.1,
                      child: child,
                    ),
                  ),
                  child: QrImageView(data: 'sync://$ip:8080', size: 200),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.of(context, rootNavigator: true).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> scanToSync({
    required BuildContext context,
    required void Function(
      List<Space> newSpaces,
      List<TableModel> newTables,
      List<Category> newMenu,
    )
    onSyncSuccess,
  }) async {
    final scannedUrl = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (ctx) => const ScannerScreen()),
    );

    if (scannedUrl == null || scannedUrl.isEmpty) return;
    await Future.delayed(const Duration(milliseconds: 120));
    if (!context.mounted) return;
    if (!scannedUrl.startsWith('sync://')) return;

    await showSmoothDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => SyncProgressDialog(
        onPerformSync: () async {
          final ipPort = scannedUrl.substring(7);
          final response = await http
              .get(Uri.parse('http://$ipPort/sync'))
              .timeout(const Duration(seconds: 5));
          if (response.statusCode != 200) {
            throw Exception('Host returned status ${response.statusCode}.');
          }
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          final syncedSpaces = (data['spaces'] as List)
              .map((e) => Space.fromJson(e))
              .toList();
          final syncedTables = (data['tables'] as List)
              .map((e) => TableModel.fromJson(e))
              .toList();
          final syncedMenu = (data['menu'] as List)
              .map((e) => Category.fromJson(e))
              .toList();
          onSyncSuccess(syncedSpaces, syncedTables, syncedMenu);
          return 'Synced ${syncedSpaces.length} spaces, '
              '${syncedTables.length} tables & ${syncedMenu.length} categories';
        },
      ),
    );
  }
}

class _PulsingStatusBadge extends StatefulWidget {
  @override
  State<_PulsingStatusBadge> createState() => _PulsingStatusBadgeState();
}

class _PulsingStatusBadgeState extends State<_PulsingStatusBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.65, end: 1.0).animate(_controller),
      child: const Chip(
        avatar: Icon(Icons.circle, color: Colors.green, size: 10),
        label: Text(
          'Server Active • Waiting for devices',
          style: TextStyle(fontSize: 10),
        ),
      ),
    );
  }
}
