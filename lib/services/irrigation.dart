import 'package:flutter/foundation.dart';

enum IrrigationMethod { drip, sprinkler }
enum GrowthStage { initial, development, mid, late }
enum Et0Preset { greenhouse, cool, normal, hot }

@immutable
class CropProfile {
  final String name;
  final Map<GrowthStage, double> kc;
  const CropProfile({required this.name, required this.kc});
}

class IrrigationInputs {
  final double areaM2;
  final double et0MmPerDay;
  final GrowthStage stage;
  final String crop;
  final int intervalDays;
  final double systemEfficiencyPercent; // КПД
  final double rainMmPerPeriod;
  final double rainEffectiveShare; // 0..1

  const IrrigationInputs({
    required this.areaM2,
    required this.et0MmPerDay,
    required this.stage,
    required this.crop,
    required this.intervalDays,
    required this.systemEfficiencyPercent,
    required this.rainMmPerPeriod,
    required this.rainEffectiveShare,
  });
}

class IrrigationResult {
  final double etcPerDayMm;
  final double etcPeriodMm;
  final double netMm;
  final double grossMm;
  final double liters;

  const IrrigationResult({
    required this.etcPerDayMm,
    required this.etcPeriodMm,
    required this.netMm,
    required this.grossMm,
    required this.liters,
  });
}

class IrrigationEngine {
  static const crops = <CropProfile>[
    CropProfile(
      name: "Томаты",
      kc: {
        GrowthStage.initial: 0.60,
        GrowthStage.development: 0.90,
        GrowthStage.mid: 1.15,
        GrowthStage.late: 0.85,
      },
    ),
    CropProfile(
      name: "Огурцы",
      kc: {
        GrowthStage.initial: 0.70,
        GrowthStage.development: 0.95,
        GrowthStage.mid: 1.10,
        GrowthStage.late: 0.85,
      },
    ),
    CropProfile(
      name: "Картофель",
      kc: {
        GrowthStage.initial: 0.50,
        GrowthStage.development: 0.80,
        GrowthStage.mid: 1.10,
        GrowthStage.late: 0.75,
      },
    ),
    CropProfile(
      name: "Пшеница",
      kc: {
        GrowthStage.initial: 0.35,
        GrowthStage.development: 0.75,
        GrowthStage.mid: 1.15,
        GrowthStage.late: 0.45,
      },
    ),
    CropProfile(
      name: "Кукуруза",
      kc: {
        GrowthStage.initial: 0.40,
        GrowthStage.development: 0.80,
        GrowthStage.mid: 1.20,
        GrowthStage.late: 0.60,
      },
    ),
    CropProfile(
      name: "Салат/зелень",
      kc: {
        GrowthStage.initial: 0.60,
        GrowthStage.development: 0.85,
        GrowthStage.mid: 0.95,
        GrowthStage.late: 0.80,
      },
    ),
  ];

  static CropProfile profileByName(String name) =>
      crops.firstWhere((c) => c.name == name, orElse: () => crops.first);

  static double kcFor(String crop, GrowthStage stage) =>
      profileByName(crop).kc[stage] ?? 1.0;

  static double defaultEfficiency(IrrigationMethod method) =>
      method == IrrigationMethod.drip ? 90 : 75;

  static double et0ByPreset(Et0Preset p) {
    switch (p) {
      case Et0Preset.greenhouse:
        return 1.8;
      case Et0Preset.cool:
        return 2.8;
      case Et0Preset.normal:
        return 4.5;
      case Et0Preset.hot:
        return 6.2;
    }
  }

  static IrrigationResult calculate(IrrigationInputs i) {
    final kc = kcFor(i.crop, i.stage);
    final etcPerDay = i.et0MmPerDay * kc;              // мм/день
    final etcPeriod = etcPerDay * i.intervalDays;      // мм/период

    final effRain = i.rainMmPerPeriod * i.rainEffectiveShare;
    final net = (etcPeriod - effRain).clamp(0, 1e9).toDouble();
    final gross = net / (i.systemEfficiencyPercent / 100.0);

    final liters = gross * i.areaM2; // 1 мм на 1 м² = 1 литр

    return IrrigationResult(
      etcPerDayMm: etcPerDay,
      etcPeriodMm: etcPeriod,
      netMm: net,
      grossMm: gross,
      liters: liters,
    );
  }
}
