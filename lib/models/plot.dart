class Plot {
  final String id;
  final String name;
  final double areaM2;

  // Saved irrigation profile (offline, per plot)
  final String crop;            // e.g. "Томаты"
  final String stage;           // GrowthStage name string
  final String method;          // "drip" | "sprinkler"
  final double efficiency;      // КПД %
  final double et0;             // мм/день (manual or preset result)
  final int intervalDays;       // days between irrigations
  final double rainMm;          // mm per period
  final double rainEffShare;    // 0..1

  Plot({
    required this.id,
    required this.name,
    required this.areaM2,
    this.crop = "Томаты",
    this.stage = "mid",
    this.method = "drip",
    this.efficiency = 90,
    this.et0 = 4.5,
    this.intervalDays = 2,
    this.rainMm = 0,
    this.rainEffShare = 0.7,
  });

  Plot copyWith({
    String? name,
    double? areaM2,
    String? crop,
    String? stage,
    String? method,
    double? efficiency,
    double? et0,
    int? intervalDays,
    double? rainMm,
    double? rainEffShare,
  }) {
    return Plot(
      id: id,
      name: name ?? this.name,
      areaM2: areaM2 ?? this.areaM2,
      crop: crop ?? this.crop,
      stage: stage ?? this.stage,
      method: method ?? this.method,
      efficiency: efficiency ?? this.efficiency,
      et0: et0 ?? this.et0,
      intervalDays: intervalDays ?? this.intervalDays,
      rainMm: rainMm ?? this.rainMm,
      rainEffShare: rainEffShare ?? this.rainEffShare,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'areaM2': areaM2,
        'crop': crop,
        'stage': stage,
        'method': method,
        'efficiency': efficiency,
        'et0': et0,
        'intervalDays': intervalDays,
        'rainMm': rainMm,
        'rainEffShare': rainEffShare,
      };

  static Plot fromMap(Map map) => Plot(
        id: map['id'],
        name: map['name'],
        areaM2: (map['areaM2'] as num).toDouble(),
        crop: (map['crop'] ?? "Томаты").toString(),
        stage: (map['stage'] ?? "mid").toString(),
        method: (map['method'] ?? "drip").toString(),
        efficiency: map['efficiency'] == null ? 90 : (map['efficiency'] as num).toDouble(),
        et0: map['et0'] == null ? 4.5 : (map['et0'] as num).toDouble(),
        intervalDays: map['intervalDays'] == null ? 2 : (map['intervalDays'] as num).toInt(),
        rainMm: map['rainMm'] == null ? 0 : (map['rainMm'] as num).toDouble(),
        rainEffShare: map['rainEffShare'] == null ? 0.7 : (map['rainEffShare'] as num).toDouble(),
      );
}
