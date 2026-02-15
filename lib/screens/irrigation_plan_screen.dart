import 'package:flutter/material.dart';
import '../models/plot.dart';
import '../services/irrigation.dart';

class IrrigationPlanScreen extends StatelessWidget {
  final Plot plot;
  const IrrigationPlanScreen({super.key, required this.plot});

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

  @override
  Widget build(BuildContext context) {
    final inputs = IrrigationInputs(
      areaM2: plot.areaM2,
      et0MmPerDay: plot.et0,
      stage: _stageFrom(plot.stage),
      crop: plot.crop,
      intervalDays: plot.intervalDays,
      systemEfficiencyPercent: plot.efficiency,
      rainMmPerPeriod: plot.rainMm,
      rainEffectiveShare: plot.rainEffShare,
    );

    final res = IrrigationEngine.calculate(inputs);

    // simple weekly plan: show next 7 days, with irrigations on day 0, interval, 2*interval...
    final now = DateTime.now();
    final irrigDays = <int>{};
    for (int d = 0; d <= 6; d += plot.intervalDays) {
      irrigDays.add(d);
    }

    return Scaffold(
      appBar: AppBar(title: Text("План на неделю • ${plot.name}")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.water_drop_outlined),
              title: Text("${res.liters.toStringAsFixed(0)} л на полив"),
              subtitle: Text(
                "Культура: ${plot.crop} • стадия ${plot.stage} • ET₀ ${plot.et0.toStringAsFixed(1)} мм/д • КПД ${plot.efficiency.toStringAsFixed(0)}%",
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
                  Text("Расчёт", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  const SizedBox(height: 8),
                  Text("ETc/день: ${res.etcPerDayMm.toStringAsFixed(2)} мм"),
                  Text("ETc за период: ${res.etcPeriodMm.toStringAsFixed(1)} мм"),
                  Text("Осадки учтены: ${(plot.rainMm * plot.rainEffShare).toStringAsFixed(1)} мм"),
                  Text("Итого (gross): ${res.grossMm.toStringAsFixed(1)} мм на полив"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text("Неделя (7 дней)", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ...List.generate(7, (d) {
            final date = now.add(Duration(days: d));
            final isIrr = irrigDays.contains(d);
            return Card(
              child: ListTile(
                leading: Icon(isIrr ? Icons.opacity : Icons.event_available),
                title: Text("${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}"),
                subtitle: Text(isIrr ? "Полив: ${res.liters.toStringAsFixed(0)} л" : "Без полива"),
                trailing: isIrr ? Text("${res.grossMm.toStringAsFixed(1)} мм") : null,
              ),
            );
          }),
        ],
      ),
    );
  }
}
