import 'package:hive_flutter/hive_flutter.dart';
import '../models/plot.dart';
import '../models/measurement.dart';

class LocalDb {
  static const plotsBoxName = 'plots';
  static const measBoxName = 'measurements';

  static Future<void> init() async {
    await Hive.initFlutter();
    await Hive.openBox(plotsBoxName);
    await Hive.openBox(measBoxName);
  }

  static Box get _plots => Hive.box(plotsBoxName);
  static Box get _meas => Hive.box(measBoxName);

  // PLOTS
  static List<Plot> getPlots() =>
      _plots.values.map((e) => Plot.fromMap(Map.from(e))).toList();

  static Future<void> upsertPlot(Plot p) async => _plots.put(p.id, p.toMap());

  static Future<void> deletePlot(String id) async {
    await _plots.delete(id);

    final keysToDelete = <dynamic>[];
    for (final k in _meas.keys) {
      final m = Map.from(_meas.get(k));
      if (m['plotId'] == id) keysToDelete.add(k);
    }
    await _meas.deleteAll(keysToDelete);
  }

  // MEASUREMENTS
  static List<Measurement> getMeasurements(String plotId) {
    final list = _meas.values
        .map((e) => Measurement.fromMap(Map.from(e)))
        .where((m) => m.plotId == plotId)
        .toList();
    list.sort((a, b) => b.ts.compareTo(a.ts));
    return list;
  }

  static Future<void> addMeasurement(Measurement m) async =>
      _meas.put(m.id, m.toMap());
}
