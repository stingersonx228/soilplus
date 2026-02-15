// ВСТАВЬ ПОЛНОСТЬЮ ВМЕСТО ТЕКУЩЕГО ФАЙЛА

import 'package:flutter/material.dart';
import '../models/plot.dart';
import '../services/local_db.dart';
import '../services/irrigation.dart';
import 'irrigation_plan_screen.dart';
import 'plot_settings_screen.dart';

class IrrigationCalcScreen extends StatefulWidget {
  const IrrigationCalcScreen({super.key});

  @override
  State<IrrigationCalcScreen> createState() => _IrrigationCalcScreenState();
}

class _IrrigationCalcScreenState extends State<IrrigationCalcScreen> {
  String? selectedPlotId;

  String crop = IrrigationEngine.crops.first.name;
  GrowthStage stage = GrowthStage.mid;
  IrrigationMethod method = IrrigationMethod.drip;

  final areaCtrl = TextEditingController(text: "100");
  final et0Ctrl = TextEditingController(text: "4.5");
  final intervalCtrl = TextEditingController(text: "2");
  final effCtrl = TextEditingController(text: "90");
  final rainCtrl = TextEditingController(text: "0");

  double rainEff = 0.7;
  bool usePreset = true;
  Et0Preset preset = Et0Preset.normal;

  IrrigationResult? result;

  double _parse(String s) =>
      double.tryParse(s.replaceAll(',', '.').trim()) ?? 0;

  void _applyPreset() {
    et0Ctrl.text = IrrigationEngine.et0ByPreset(preset).toStringAsFixed(1);
  }

  void _loadFromPlot(Plot p) {
    selectedPlotId = p.id;

    crop = p.crop;
    stage = GrowthStage.values.firstWhere(
      (e) => e.name == p.stage,
      orElse: () => GrowthStage.mid,
    );

    method = p.method == "sprinkler"
        ? IrrigationMethod.sprinkler
        : IrrigationMethod.drip;

    areaCtrl.text = p.areaM2.toStringAsFixed(1);
    et0Ctrl.text = p.et0.toStringAsFixed(1);
    intervalCtrl.text = p.intervalDays.toString();
    effCtrl.text = p.efficiency.toStringAsFixed(0);
    rainCtrl.text = p.rainMm.toStringAsFixed(0);
    rainEff = p.rainEffShare;

    result = null;
    setState(() {});
  }

  void _calc() {
    final inputs = IrrigationInputs(
      areaM2: _parse(areaCtrl.text),
      et0MmPerDay: _parse(et0Ctrl.text),
      stage: stage,
      crop: crop,
      intervalDays: _parse(intervalCtrl.text).toInt(),
      systemEfficiencyPercent: _parse(effCtrl.text),
      rainMmPerPeriod: _parse(rainCtrl.text),
      rainEffectiveShare: rainEff,
    );

    setState(() {
      result = IrrigationEngine.calculate(inputs);
    });
  }

  Future<void> _saveToPlot() async {
    final plots = LocalDb.getPlots();
    final p = selectedPlotId == null
        ? null
        : plots.firstWhere((x) => x.id == selectedPlotId);

    if (p == null) return;

    final updated = p.copyWith(
      areaM2: _parse(areaCtrl.text),
      crop: crop,
      stage: stage.name,
      method: method.name,
      et0: _parse(et0Ctrl.text),
      intervalDays: _parse(intervalCtrl.text).toInt(),
      efficiency: _parse(effCtrl.text),
      rainMm: _parse(rainCtrl.text),
      rainEffShare: rainEff,
    );

    await LocalDb.upsertPlot(updated);
    _loadFromPlot(updated);
  }

  @override
  Widget build(BuildContext context) {
    final plots = LocalDb.getPlots();

    final Plot? selectedPlot = selectedPlotId == null
        ? null
        : plots.where((p) => p.id == selectedPlotId).isNotEmpty
            ? plots.firstWhere((p) => p.id == selectedPlotId)
            : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Калькулятор орошения"),
        actions: [
          if (selectedPlot != null)
            IconButton(
              icon: const Icon(Icons.calendar_month),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => IrrigationPlanScreen(plot: selectedPlot),
                ),
              ),
            )
        ],
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          /// УЧАСТОК
          DropdownButtonFormField<String?>(
            value: selectedPlotId,
            items: [
              const DropdownMenuItem(value: null, child: Text("— без участка —")),
              ...plots.map((p) => DropdownMenuItem(
                    value: p.id,
                    child: Text("${p.name} • ${p.areaM2} м²"),
                  )),
            ],
            onChanged: (id) {
              if (id == null) {
                setState(() => selectedPlotId = null);
              } else {
                _loadFromPlot(plots.firstWhere((p) => p.id == id));
              }
            },
            decoration: const InputDecoration(border: OutlineInputBorder()),
          ),

          const SizedBox(height: 16),

          /// КУЛЬТУРА
          DropdownButtonFormField<String>(
            value: crop,
            items: IrrigationEngine.crops
                .map((c) => DropdownMenuItem(value: c.name, child: Text(c.name)))
                .toList(),
            onChanged: (v) => setState(() => crop = v!),
            decoration: const InputDecoration(labelText: "Культура"),
          ),

          const SizedBox(height: 12),

          /// СТАДИЯ
          DropdownButtonFormField<GrowthStage>(
            value: stage,
            items: GrowthStage.values
                .map((s) => DropdownMenuItem(value: s, child: Text(s.name)))
                .toList(),
            onChanged: (v) => setState(() => stage = v!),
            decoration: const InputDecoration(labelText: "Стадия"),
          ),

          const SizedBox(height: 12),

          /// МЕТОД ПОЛИВА
          DropdownButtonFormField<IrrigationMethod>(
            value: method,
            items: IrrigationMethod.values
                .map((m) => DropdownMenuItem(value: m, child: Text(m.name)))
                .toList(),
            onChanged: (v) => setState(() => method = v!),
            decoration: const InputDecoration(labelText: "Метод полива"),
          ),

          const SizedBox(height: 12),

          /// ET0 ПРЕСЕТ
          SwitchListTile(
            title: const Text("Использовать ET₀ пресет"),
            value: usePreset,
            onChanged: (v) => setState(() => usePreset = v),
          ),

          if (usePreset)
            DropdownButtonFormField<Et0Preset>(
              value: preset,
              items: Et0Preset.values
                  .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                  .toList(),
              onChanged: (v) {
                setState(() => preset = v!);
                _applyPreset();
              },
              decoration: const InputDecoration(labelText: "ET₀ режим"),
            ),

          const SizedBox(height: 12),

          TextField(
            controller: et0Ctrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "ET₀ (мм/день)"),
          ),

          TextField(
            controller: intervalCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Интервал (дни)"),
          ),

          TextField(
            controller: effCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "КПД (%)"),
          ),

          TextField(
            controller: rainCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: "Осадки (мм)"),
          ),

          const SizedBox(height: 16),

          FilledButton(
            onPressed: _calc,
            child: const Text("Рассчитать"),
          ),

          if (result != null)
            Card(
              child: ListTile(
                title: Text("${result!.liters.toStringAsFixed(0)} литров"),
                subtitle: Text("${result!.grossMm.toStringAsFixed(1)} мм"),
                trailing: selectedPlot != null
                    ? IconButton(
                        icon: const Icon(Icons.save),
                        onPressed: _saveToPlot,
                      )
                    : null,
              ),
            ),
        ],
      ),
    );
  }
}
