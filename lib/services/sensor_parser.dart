import 'dart:convert';

class SensorReading {
  final double? ph;
  final double? moisture;
  final double? ec;

  const SensorReading({this.ph, this.moisture, this.ec});

  bool get hasAny => ph != null || moisture != null || ec != null;
}

/// Supported formats:
/// 1) "ph=6.5;moist=35;ec=1.2"
/// 2) "6.5,35,1.2"  (pH, moisture, EC)
/// 3) JSON: {"ph":6.5,"moisture":35,"ec":1.2}
class SensorParser {
  static SensorReading parse(List<int> bytes) {
    final raw = _decodeBestEffort(bytes).trim();
    if (raw.isEmpty) return const SensorReading();

    // JSON
    if (raw.startsWith('{') && raw.endsWith('}')) {
      try {
        final map = jsonDecode(raw) as Map;
        return SensorReading(
          ph: _toDouble(map['ph']),
          moisture: _toDouble(map['moisture'] ?? map['moist']),
          ec: _toDouble(map['ec']),
        );
      } catch (_) {}
    }

    // key=value;key=value
    if (raw.contains('=') || raw.contains(':')) {
      final parts = raw.split(RegExp(r'[;,\n\r]+'));
      double? ph, moist, ec;

      for (final p in parts) {
        final seg = p.trim();
        if (seg.isEmpty) continue;

        final kv = seg.split(RegExp(r'[:=]'));
        if (kv.length < 2) continue;

        final k = kv[0].trim().toLowerCase();
        final v = kv.sublist(1).join(':').trim();

        final dv = _toDouble(v);
        if (dv == null) continue;

        if (k.contains('ph')) ph = dv;
        if (k.contains('moist') || k.contains('humidity')) moist = dv;
        if (k == 'ec' || k.contains('conduct')) ec = dv;
      }
      return SensorReading(ph: ph, moisture: moist, ec: ec);
    }

    // CSV
    if (raw.contains(',')) {
      final nums = raw
          .split(',')
          .map((s) => _toDouble(s.trim()))
          .where((v) => v != null)
          .cast<double>()
          .toList();
      if (nums.isEmpty) return const SensorReading();
      return SensorReading(
        ph: nums.length > 0 ? nums[0] : null,
        moisture: nums.length > 1 ? nums[1] : null,
        ec: nums.length > 2 ? nums[2] : null,
      );
    }

    // single number -> moisture
    final one = _toDouble(raw);
    if (one != null) return SensorReading(moisture: one);

    return const SensorReading();
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    final s = v.toString().replaceAll(',', '.').trim();
    return double.tryParse(s);
  }

  static String _decodeBestEffort(List<int> bytes) {
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return String.fromCharCodes(bytes);
    }
  }
}
