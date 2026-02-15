import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/plot.dart';
import 'bluetooth_device_screen.dart';

class BluetoothScanScreen extends StatefulWidget {
  final Plot plot;
  const BluetoothScanScreen({super.key, required this.plot});

  @override
  State<BluetoothScanScreen> createState() => _BluetoothScanScreenState();
}

class _BluetoothScanScreenState extends State<BluetoothScanScreen> {
  StreamSubscription<List<ScanResult>>? _sub;
  final Map<DeviceIdentifier, ScanResult> _results = {};
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _sub?.cancel();
    FlutterBluePlus.stopScan();
    super.dispose();
  }

  Future<void> _start() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Включи Bluetooth (в эмуляторе BLE часто ограничен).")),
      );
      return;
    }

    setState(() {
      _results.clear();
      _scanning = true;
    });

    await FlutterBluePlus.startScan(timeout: const Duration(seconds: 8));

    _sub?.cancel();
    _sub = FlutterBluePlus.scanResults.listen((list) {
      for (final r in list) {
        _results[r.device.remoteId] = r;
      }
      if (mounted) setState(() {});
    });

    Future.delayed(const Duration(seconds: 9), () {
      if (mounted) setState(() => _scanning = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final items = _results.values.toList()..sort((a, b) => b.rssi.compareTo(a.rssi));

    return Scaffold(
      appBar: AppBar(
        title: Text("Bluetooth • ${widget.plot.name}"),
        actions: [
          IconButton(
            icon: Icon(_scanning ? Icons.hourglass_top : Icons.refresh),
            onPressed: _scanning ? null : _start,
          ),
        ],
      ),
      body: items.isEmpty
          ? const Center(child: Text("Устройств не видно. Обнови и держи датчик рядом.\n\nВажно: BLE в эмуляторе может не работать — лучше реальный телефон Android 7+."))
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final r = items[i];
                final name = r.device.platformName.isNotEmpty ? r.device.platformName : "(без имени)";
                return ListTile(
                  leading: const Icon(Icons.bluetooth),
                  title: Text(name),
                  subtitle: Text("${r.device.remoteId.str}  •  RSSI ${r.rssi}"),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BluetoothDeviceScreen(plot: widget.plot, device: r.device),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
