import 'package:flutter/material.dart';
import '../models/plot.dart';
import '../services/local_db.dart';
import '../services/irrigation.dart';

class PlotSettingsScreen extends StatefulWidget {
  final Plot plot;
  const PlotSettingsScreen({super.key, required this.plot});

  @override
  State<PlotSettingsScreen> createState() => _PlotSettingsScreenState();
}

class _PlotSettingsScreenState extends State<PlotSettingsScreen> {
  late Plot p;

  late String crop;
  late GrowthStage stage;
  late IrrigationMethod method;

  final et0Ctrl = TextEditingController();
  Et0Preset preset = Et0Preset.normal;
  bool usePreset = true;

  final intervalCtrl = TextEditingController();
  final effCtrl = TextEditingController();
  final rainCtrl = TextEditingController();
  double rainEff = 0.7;

  @override
  void initState() {
    super.initState();
    p = widget.plot;

    crop = p.crop;
    stage = _stageFrom(p.stage);
    method = p.method == "sprinkler" ? IrrigationMethod.sprinkler : IrrigationMethod.drip;

    usePreset = true;
    preset = Et0Preset.normal;
    et0Ctrl.text = p.et0.toStringAsFixed(1);

    intervalCtrl.text = p.intervalDays.toString();
    effCtrl.text = p.efficiency.toStringAsFixed(0);
    rainCtrl.text = p.rainMm.toStringAsFixed(0);
    rainEff = p.rainEffShare;
  }

  GrowthStage _stageFrom(String s) {
    switch (s) {
      case "initial":
        return GrowthStage.initial;
      case "development":
        return GrowthStage.development;
      case "late":
        return GrowthStage.late;
      default:
        return GrowthStage.mid;
    }
  }

  String _stageTo(GrowthStage s) {
    switch (s) {
      case GrowthStage.initial:
        return "initial";
      case GrowthStage.development:
        return "development";
      case GrowthStage.late:
        return "late";
      case GrowthStage.mid:
        return "mid";
    }
  }

  String _stageName(GrowthStage s) => switch (s) {
        GrowthStage.initial => "Старт",
        GrowthStage.development => "Развитие",
        GrowthStage.mid => "Пик",
        GrowthStage.late => "Финиш",
      };

  String _methodName(IrrigationMethod m) => m == IrrigationMethod.drip ? "Капля" : "Дождевание";

  String _presetName(Et0Preset p) => switch (p) {
        Et0Preset.greenhouse => "Теплица/прохлада",
        Et0Preset.cool => "Прохладно",
        Et0Preset.normal => "Норма",
        Et0Preset.hot => "Жара",
      };

  double _parse(String s) => double.tryParse(s.replaceAll(',', '.').trim()) ?? 0;

  void _applyPreset() {
    final v = IrrigationEngine.et0ByPreset(preset);
    et0Ctrl.text = v.toStringAsFixed(1);
  }

  Future<void> _save() async {
    final et0 = _parse(et0Ctrl.text);
    final interval = _parse(intervalCtrl.text).toInt();
    final eff = _parse(effCtrl.text);
    final rain = _parse(rainCtrl.text);

    if (et0 <= 0 || interval <= 0 || eff <= 0) return;

    final updated = p.copyWith(
      crop: crop,
      stage: _stageTo(stage),
      method: method == IrrigationMethod.sprinkler ? "sprinkler" : "drip",
      et0: et0,
      intervalDays: interval,
      efficiency: eff,
      rainMm: rain,
      rainEffShare: rainEff,
    );

    await LocalDb.upsertPlot(updated);

    if (!mounted) return;
    Navigator.pop(context, updated);
  }

  @override
  Widget build(BuildContext context) {
    final cropItems = IrrigationEngine.crops.map((c) => c.name).toList();

    return Scaffold(
      appBar: AppBar(title: Text("Профиль полива • ${p.name}")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Культура", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: crop,
                    items: cropItems.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
                    onChanged: (v) => setState(() => crop = v ?? cropItems.first),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  const Text("Стадия", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<GrowthStage>(
                    value: stage,
                    items: GrowthStage.values
                        .map((s) => DropdownMenuItem(value: s, child: Text(_stageName(s))))
                        .toList(),
                    onChanged: (v) => setState(() => stage = v ?? GrowthStage.mid),
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  DropdownButtonFormField<IrrigationMethod>(
                    value: method,
                    items: IrrigationMethod.values
                        .map((m) => DropdownMenuItem(value: m, child: Text(_methodName(m))))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        method = v ?? IrrigationMethod.drip;
                        effCtrl.text = IrrigationEngine.defaultEfficiency(method).toStringAsFixed(0);
                      });
                    },
                    decoration: const InputDecoration(labelText: "Метод", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: effCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "КПД системы (%)", border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text("ET₀ по пресету (оффлайн)"),
                          value: usePreset,
                          onChanged: (v) => setState(() => usePreset = v),
                        ),
                      ),
                    ],
                  ),
                  if (usePreset) ...[
                    DropdownButtonFormField<Et0Preset>(
                      value: preset,
                      items: Et0Preset.values
                          .map((p) => DropdownMenuItem(value: p, child: Text(_presetName(p))))
                          .toList(),
                      onChanged: (v) {
                        setState(() => preset = v ?? Et0Preset.normal);
                        _applyPreset();
                      },
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 10),
                  ],
                  TextField(
                    controller: et0Ctrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "ET₀ (мм/день)", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: intervalCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Интервал между поливами (дней)", border: OutlineInputBorder()),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  TextField(
                    controller: rainCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: "Осадки за период (мм)", border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Expanded(child: Text("Эффективность осадков")),
                      Text(rainEff.toStringAsFixed(2)),
                    ],
                  ),
                  Slider(
                    value: rainEff,
                    min: 0,
                    max: 1,
                    divisions: 20,
                    onChanged: (v) => setState(() => rainEff = v),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save),
            label: const Text("Сохранить в участок"),
          ),
        ],
      ),
    );
  }
}
