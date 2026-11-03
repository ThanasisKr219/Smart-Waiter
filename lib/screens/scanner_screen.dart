import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  late MobileScannerController cameraController;
  bool _isScanned = false;

  @override
  void initState() {
    super.initState();
    cameraController = MobileScannerController();
  }

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receive Data (Wi-Fi)')),
      body: MobileScanner(
        controller: cameraController,
        onDetect: (capture) async {
          if (_isScanned) return;
          final barcode = capture.barcodes.first.rawValue;
          if (barcode != null && barcode.startsWith('sync://')) {
            _isScanned = true;
            await cameraController.stop();
            if (mounted) {
              Navigator.pop(context, barcode);
            }
          }
        },
      ),
    );
  }
}