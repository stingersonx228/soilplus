import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/plot.dart';
import '../models/measurement.dart';
import '../services/local_db.dart';
import '../services/recommendations.dart';
import '../widgets/kv_row.dart';
import 'bluetooth_scan_screen.dart';
import 'plot_settings_screen.dart';
import 'irrigation_plan_screen.dart';

class PlotDetailScreen extends StatefulWidget {
  final Plot plot;
  const PlotDetailScreen({super.key, required this.plot});

  @override
  State<PlotDetailScreen> createState() => _PlotDetailScreenState();
}

class _PlotDetailScreenState extends State<PlotDetailScreen> {
  final _uuid = const Uuid();
  late Plot p;

  @override
  void initState() {
    super.initState();
    p = widget.plot;
  }

  @override
  Widget build(BuildContext context) {
    final list = LocalDb.getMeasurements(p.id);

    return Scaffold(
      appBar: AppBar(title: Text(p.name)),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addMeasurementDialog(context),
        child: const Icon(Icons.add_chart),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: [
                    ListTile(
                      title: Text("Площадь: ${p.areaM2.toStringAsFixed(1)} м²"),
                      subtitle: Text("Профиль полива: ${p.crop} • стадия ${p.stage} • ET₀ ${p.et0.toStringAsFixed(1)}"),
                      trailing: OutlinedButton.icon(
                        onPressed: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => BluetoothScanScreen(plot: p)),
                          );
                          setState(() {});
                        },
                        icon: const Icon(Icons.bluetooth),
                        label: const Text("Датчик"),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () async {
                                final updated = await Navigator.push<Plot?>(
                                  context,
                                  MaterialPageRoute(builder: (_) => PlotSettingsScreen(plot: p)),
                                );
                                if (updated != null) {
                                  setState(() => p = updated);
                                }
                              },
                              icon: const Icon(Icons.tune),
                              label: const Text("Профиль"),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => IrrigationPlanScreen(plot: p)),
                                );
                              },
                              icon: const Icon(Icons.calendar_month),
                              label: const Text("Неделя"),
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (list.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Последний замер", style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            KvRow(k: "Дата", v: list.first.ts.toString()),
                            KvRow(k: "pH", v: list.first.ph?.toStringAsFixed(2) ?? "—"),
                            KvRow(k: "Влажн.%", v: list.first.moisturePercent?.toStringAsFixed(0) ?? "—"),
                            KvRow(k: "EC", v: list.first.ec?.toStringAsFixed(2) ?? "—"),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? const Center(child: Text("Замеров нет. Добавь первый."))
                : ListView.separated(
                    itemCount: list.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (_, i) {
                      final m = list[i];
                      final ph = m.ph?.toStringAsFixed(2) ?? "—";
                      final w = m.moisturePercent?.toStringAsFixed(0) ?? "—";
                      final ec = m.ec?.toStringAsFixed(2) ?? "—";
                      return ListTile(
                        title: Text(m.ts.toString()),
                        subtitle: Text("pH: $ph   Влажн.: $w%   EC: $ec"),
                        onTap: () => _showRecommendations(m),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _showRecommendations(Measurement m) {
    final tips = Recommendations.forMeasurement(m);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Рекомендации", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...tips.map((t) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("• "),
                  Expanded(child: Text(t)),
                ],
              ),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _addMeasurementDialog(BuildContext context) async {
    final phCtrl = TextEditingController();
    final moistCtrl = TextEditingController();
    final ecCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Новый замер (вручную)"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: phCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "pH (например 6.5)")),
            TextField(controller: moistCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Влажность % (например 35)")),
            TextField(controller: ecCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "EC (опц., например 1.2)")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Отмена")),
          FilledButton(
            onPressed: () async {
              double? parse(String s) {
                final v = s.trim();
                if (v.isEmpty) return null;
                return double.tryParse(v.replaceAll(',', '.'));
              }

              final m = Measurement(
                id: _uuid.v4(),
                plotId: p.id,
                ts: DateTime.now(),
                ph: parse(phCtrl.text),
                moisturePercent: parse(moistCtrl.text),
                ec: parse(ecCtrl.text),
              );

              await LocalDb.addMeasurement(m);
              if (context.mounted) Navigator.pop(context);
              setState(() {});
            },
            child: const Text("Сохранить"),
          ),
        ],
      ),
    );
  }
}
