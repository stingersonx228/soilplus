import '../models/measurement.dart';

class Recommendations {
  static List<String> forMeasurement(Measurement m) {
    final tips = <String>[];

    if (m.ph != null) {
      final ph = m.ph!;
      if (ph < 5.5) {
        tips.add(
            "pH низкий ($ph). Часто помогает известкование (доломит/мел) малыми дозами.");
      } else if (ph > 7.5) {
        tips.add(
            "pH высокий ($ph). Возможны проблемы с усвоением микроэлементов — подкисление/органика.");
      } else {
        tips.add("pH в норме ($ph). Хорошая база.");
      }
    } else {
      tips.add("Добавь pH — это главный ориентир для рекомендаций.");
    }

    if (m.moisturePercent != null) {
      final w = m.moisturePercent!;
      if (w < 20) {
        tips.add("Влажность низкая ($w%). Нужен полив/мульча.");
      } else if (w > 60) {
        tips.add("Влажность высокая ($w%). Риск переувлажнения — проверь дренаж.");
      } else {
        tips.add("Влажность нормальная ($w%). Держи режим.");
      }
    } else {
      tips.add("Добавь влажность % — тогда советы точнее.");
    }

    if (m.ec != null) {
      final ec = m.ec!;
      if (ec > 2.0) tips.add("EC высокий ($ec). Возможна засолённость — осторожнее с удобрениями.");
      if (ec < 0.3) tips.add("EC низкий ($ec). Возможно мало питания.");
    }

    return tips;
  }
}
