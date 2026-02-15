import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:uuid/uuid.dart';
import '../models/plot.dart';
import '../models/measurement.dart';
import '../services/local_db.dart';
import '../services/sensor_parser.dart';

class BluetoothSelectCharacteristicScreen extends StatefulWidget {
  final Plot plot;
  final BluetoothDevice device;

  const BluetoothSelectCharacteristicScreen({super.key, required this.plot, required this.device});

  @override
  State<BluetoothSelectCharacteristicScreen> createState() => _BluetoothSelectCharacteristicScreenState();
}

class _BluetoothSelectCharacteristicScreenState extends State<BluetoothSelectCharacteristicScreen> {
  final _uuid = const Uuid();
  bool _loading = true;
  List<BluetoothService> _services = [];
  String _log = "";
  StreamSubscription<List<int>>? _notifySub;
  BluetoothCharacteristic? _activeChar;

  @override
  void initState() {
    super.initState();
    _discover();
  }

  @override
  void dispose() {
    _notifySub?.cancel();
    _stopNotify();
    super.dispose();
  }

  Future<void> _discover() async {
    setState(() => _loading = true);
    try {
      _services = await widget.device.discoverServices();
    } catch (e) {
      _log = "discoverServices error: $e";
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _stopNotify() async {
    if (_activeChar == null) return;
    try { await _activeChar!.setNotifyValue(false); } catch (_) {}
    _activeChar = null;
  }

  Future<void> _useCharacteristic(BluetoothCharacteristic c) async {
    await _notifySub?.cancel();
    await _stopNotify();

    setState(() {
      _activeChar = c;
      _log = "Selected: ${c.uuid}\n";
    });

    if (c.properties.notify || c.properties.indicate) {
      try {
        await c.setNotifyValue(true);
        _notifySub = c.lastValueStream.listen((bytes) async {
          await _handleIncoming(bytes, source: "notify");
        });
        setState(() => _log += "Notify ON. Waiting data...\n");
      } catch (e) {
        setState(() => _log += "Notify error: $e\n");
      }
    }

    if (!c.properties.read) {
      setState(() => _log += "Read not supported. Wait notify from device.\n");
    }
  }

  Future<void> _readOnce() async {
    final c = _activeChar;
    if (c == null) return;
    if (!c.properties.read) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Read не поддерживается.")));
      return;
    }
    try {
      final bytes = await c.read();
      await _handleIncoming(bytes, source: "read");
    } catch (e) {
      setState(() => _log += "Read error: $e\n");
    }
  }

  Future<void> _handleIncoming(List<int> bytes, {required String source}) async {
    final reading = SensorParser.parse(bytes);
    final raw = _safePreview(bytes);

    setState(() => _log += "[$source] raw: $raw\n");

    if (!reading.hasAny) {
      setState(() => _log += "Parser: no values found. Adjust SensorParser.\n");
      return;
    }

    final m = Measurement(
      id: _uuid.v4(),
      plotId: widget.plot.id,
      ts: DateTime.now(),
      ph: reading.ph,
      moisturePercent: reading.moisture,
      ec: reading.ec,
    );

    await LocalDb.addMeasurement(m);

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Замер сохранён.")));
  }

  String _safePreview(List<int> bytes) {
    final s = String.fromCharCodes(bytes.where((b) => b >= 9 && b <= 126));
    if (s.trim().isNotEmpty) return s.length > 120 ? "${s.substring(0,120)}…" : s;
    return bytes.length > 24 ? "${bytes.take(24).toList()}…" : bytes.toString();
  }

  @override
  Widget build(BuildContext context) {
    final tiles = <Widget>[];

    for (final s in _services) {
      tiles.add(Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
        child: Text("Service: ${s.uuid}", style: const TextStyle(fontWeight: FontWeight.bold)),
      ));

      for (final c in s.characteristics) {
        final props = [
          if (c.properties.read) "read",
          if (c.properties.write) "write",
          if (c.properties.writeWithoutResponse) "writeNR",
          if (c.properties.notify) "notify",
          if (c.properties.indicate) "indicate",
        ].join(", ");

        tiles.add(ListTile(
          leading: const Icon(Icons.memory),
          title: Text("Char: ${c.uuid}"),
          subtitle: Text(props.isEmpty ? "no props" : props),
          trailing: _activeChar?.uuid == c.uuid ? const Icon(Icons.check) : null,
          onTap: () => _useCharacteristic(c),
        ));
        tiles.add(const Divider(height: 1));
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Выбор характеристики"),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loading ? null : _discover)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Участок: ${widget.plot.name}"),
                          const SizedBox(height: 8),
                          Text(_activeChar == null ? "Выбери характеристику ниже." : "Активная: ${_activeChar!.uuid}"),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: _activeChar == null ? null : _readOnce,
                                  icon: const Icon(Icons.download),
                                  label: const Text("Read"),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () async {
                                    await _notifySub?.cancel();
                                    await _stopNotify();
                                    if (mounted) setState(() => _log += "Stopped.\n");
                                  },
                                  icon: const Icon(Icons.stop),
                                  label: const Text("Stop"),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text("Лог:", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                          const SizedBox(height: 6),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: Theme.of(context).colorScheme.surfaceContainerHighest,
                            ),
                            child: Text(_log.isEmpty ? "…" : _log, style: const TextStyle(fontFamily: "monospace")),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView(
                    children: tiles.isEmpty
                        ? [const Center(child: Padding(padding: EdgeInsets.all(24), child: Text("Сервисы не найдены.")))]
                        : tiles,
                  ),
                ),
              ],
            ),
    );
  }
}
