import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/plot.dart';
import '../services/local_db.dart';
import 'plot_detail_screen.dart';

class PlotsScreen extends StatefulWidget {
  const PlotsScreen({super.key});

  @override
  State<PlotsScreen> createState() => _PlotsScreenState();
}

class _PlotsScreenState extends State<PlotsScreen> {
  final _uuid = const Uuid();

  @override
  Widget build(BuildContext context) {
    final plots = LocalDb.getPlots();

    return Scaffold(
      appBar: AppBar(title: const Text("SoilPlus — участки")),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addPlotDialog(context),
        child: const Icon(Icons.add),
      ),
      body: plots.isEmpty
          ? const Center(child: Text("Пока пусто. Добавь первый участок."))
          : ListView.separated(
              itemCount: plots.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) {
                final p = plots[i];
                return ListTile(
                  title: Text(p.name),
                  subtitle: Text("Площадь: ${p.areaM2.toStringAsFixed(1)} м²"),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PlotDetailScreen(plot: p)),
                  ).then((_) => setState(() {})),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () async {
                      await LocalDb.deletePlot(p.id);
                      setState(() {});
                    },
                  ),
                );
              },
            ),
    );
  }

  Future<void> _addPlotDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final areaCtrl = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Новый участок"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: "Название")),
            TextField(
              controller: areaCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Площадь (м²)"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Отмена")),
          FilledButton(
            onPressed: () async {
              final name = nameCtrl.text.trim();
              final area = double.tryParse(areaCtrl.text.replaceAll(',', '.')) ?? 0;
              if (name.isEmpty || area <= 0) return;

              await LocalDb.upsertPlot(Plot(id: _uuid.v4(), name: name, areaM2: area));
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
