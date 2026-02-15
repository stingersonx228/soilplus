class Measurement {
  final String id;
  final String plotId;
  final DateTime ts;
  final double? ph;
  final double? moisturePercent;
  final double? ec;

  Measurement({
    required this.id,
    required this.plotId,
    required this.ts,
    this.ph,
    this.moisturePercent,
    this.ec,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'plotId': plotId,
        'ts': ts.toIso8601String(),
        'ph': ph,
        'moisturePercent': moisturePercent,
        'ec': ec,
      };

  static Measurement fromMap(Map map) => Measurement(
        id: map['id'],
        plotId: map['plotId'],
        ts: DateTime.parse(map['ts']),
        ph: map['ph'] == null ? null : (map['ph'] as num).toDouble(),
        moisturePercent: map['moisturePercent'] == null
            ? null
            : (map['moisturePercent'] as num).toDouble(),
        ec: map['ec'] == null ? null : (map['ec'] as num).toDouble(),
      );
}
