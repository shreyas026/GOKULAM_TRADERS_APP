import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerDialog extends StatefulWidget {
  final Function(String code) onScan;

  const BarcodeScannerDialog({super.key, required this.onScan});

  @override
  State<BarcodeScannerDialog> createState() => _BarcodeScannerDialogState();
}

class _BarcodeScannerDialogState extends State<BarcodeScannerDialog> {
  MobileScannerController? _controller;
  bool _detected = false;

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppBar(
            title: const Text('Scan Barcode'),
            automaticallyImplyLeading: false,
            actions: [
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          SizedBox(
            height: 300,
            child: MobileScanner(
              controller: _controller,
              onDetect: (capture) {
                if (_detected) return;
                _detected = true;
                final code = capture.barcodes.first.rawValue ?? '';
                if (code.isNotEmpty) {
                  Navigator.pop(context);
                  widget.onScan(code);
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}