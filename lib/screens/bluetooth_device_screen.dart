import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import '../models/plot.dart';
import 'bluetooth_select_characteristic_screen.dart';

class BluetoothDeviceScreen extends StatefulWidget {
  final Plot plot;
  final BluetoothDevice device;

  const BluetoothDeviceScreen({super.key, required this.plot, required this.device});

  @override
  State<BluetoothDeviceScreen> createState() => _BluetoothDeviceScreenState();
}

class _BluetoothDeviceScreenState extends State<BluetoothDeviceScreen> {
  StreamSubscription<BluetoothConnectionState>? _connSub;
  BluetoothConnectionState _state = BluetoothConnectionState.disconnected;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _connSub = widget.device.connectionState.listen((s) {
      if (mounted) setState(() => _state = s);
    });
  }

  @override
  void dispose() {
    _connSub?.cancel();
    super.dispose();
  }

  Future<void> _connect() async {
    setState(() => _busy = true);
    try {
      await widget.device.connect(timeout: const Duration(seconds: 12), autoConnect: false);
    } catch (_) {
      // ignore (already connected etc.)
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _disconnect() async {
    setState(() => _busy = true);
    try {
      await widget.device.disconnect();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final name = widget.device.platformName.isNotEmpty ? widget.device.platformName : "(без имени)";

    return Scaffold(
      appBar: AppBar(title: Text(name)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              child: ListTile(
                title: Text(widget.device.remoteId.str),
                subtitle: Text("Состояние: $_state"),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: (_state == BluetoothConnectionState.connected || _busy) ? null : _connect,
                    icon: const Icon(Icons.link),
                    label: const Text("Подключить"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: (_state != BluetoothConnectionState.connected || _busy) ? null : _disconnect,
                    icon: const Icon(Icons.link_off),
                    label: const Text("Отключить"),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _state == BluetoothConnectionState.connected
                  ? () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BluetoothSelectCharacteristicScreen(plot: widget.plot, device: widget.device),
                        ),
                      );
                    }
                  : null,
              icon: const Icon(Icons.tune),
              label: const Text("Выбрать характеристику"),
            ),
            const SizedBox(height: 10),
            const Text("Подсказка: нужна характеристика с Notify/Indicate или Read."),
          ],
        ),
      ),
    );
  }
}
