#include <SoftwareSerial.h>
#include <OneWire.h>
#include <DallasTemperature.h>

// ---------- PIN CONFIG ----------
const int PIN_MOIST = A0;   // влажность (аналог)
const int PIN_TDS   = A1;   // TDS модуль (аналог)
const int PIN_PH    = A2;   // pH модуль (аналог)

const int PIN_ONEWIRE = 4;  // DS18B20 DATA -> D4

// Bluetooth: Arduino (D10=RX <- TX модуля), (D11=TX -> RX модуля через делитель/резистор)
SoftwareSerial bt(10, 11); // RX, TX

OneWire oneWire(PIN_ONEWIRE);
DallasTemperature tempSensors(&oneWire);

// ---------- TUNING / CALIBRATION ----------
// Влажность: подстрой под себя (сухо/вода). Сейчас примерные значения.
int MOIST_DRY = 650;   // сырой ADC в сухом воздухе/сухой почве
int MOIST_WET = 350;   // сырой ADC во влажной среде/почти в воде

// TDS: коэффициент калибровки (под свой модуль и питание)
// Если TDS слишком большой/маленький — корректируй TDS_K.
float TDS_K = 1.0;     // множитель калибровки

// pH: без буферов точный pH не получить. Пока выводим RAW и "примерный pH" по грубой линии.
// Чтобы было по-взрослому — позже калибруем по 2 точкам (pH 4 и pH 7).
float PH_SLOPE = -5.7;  // грубая оценка, поменяешь после калибровки
float PH_OFFSET = 21.34;

// ---------- HELPERS ----------
int analogReadStable(int pin, int samples = 10) {
  // 1) "прогрев" АЦП после переключения канала (убирает часть скачков)
  (void)analogRead(pin);
  delay(2);

  long sum = 0;
  for (int i = 0; i < samples; i++) {
    sum += analogRead(pin);
    delay(2);
  }
  return (int)(sum / samples);
}

int clampInt(int v, int lo, int hi) {
  if (v < lo) return lo;
  if (v > hi) return hi;
  return v;
}

int mapMoistPercent(int raw) {
  // Чем меньше raw у ёмкостного датчика — тем влажнее (обычно так)
  int pct = (int)( ( (float)(MOIST_DRY - raw) / (float)(MOIST_DRY - MOIST_WET) ) * 100.0 );
  return clampInt(pct, 0, 100);
}

float adcToVoltage(int raw) {
  // Arduino UNO: 10-bit ADC, опорное обычно 5.0V (по USB может быть 4.6-5.1)
  // Для более точного — измерь реальное 5V мультиметром и подставь вместо 5.0
  return (raw * 5.0) / 1023.0;
}

float calcTdsPpm(int rawTds, float tempC) {
  // Много модулей TDS дают аналог, который зависит от температуры.
  // Ниже — распространённая формула из типовых примеров (не идеальна, но рабочая для прототипа).
  float voltage = adcToVoltage(rawTds);

  // Температурная компенсация (25°C базовая)
  float compensationCoefficient = 1.0 + 0.02 * (tempC - 25.0);
  float compensationVoltage = voltage / compensationCoefficient;

  // Полиномиальная аппроксимация (часто встречается для Gravity TDS)
  float tds = (133.42 * compensationVoltage * compensationVoltage * compensationVoltage
             - 255.86 * compensationVoltage * compensationVoltage
             + 857.39 * compensationVoltage) * 0.5;

  if (tds < 0) tds = 0;
  return tds * TDS_K;
}

float calcPhApprox(int rawPh) {
  // Грубая оценка, если вдруг нужно "pH:" показывать.
  // Без калибровки буферами это будет НЕТОЧНО — но как демо для конкурса пойдёт.
  float v = adcToVoltage(rawPh);
  float ph = PH_SLOPE * v + PH_OFFSET;
  return ph;
}

// ---------- SETUP ----------
void setup() {
  Serial.begin(9600);
  bt.begin(9600);

  tempSensors.begin();

  Serial.println("SoilPlus START");
  bt.println("SoilPlus START");
}

// ---------- LOOP ----------
void loop() {
  // 1) Температура
  tempSensors.requestTemperatures();
  float tC = tempSensors.getTempCByIndex(0);
  // Если датчик не найден, DallasTemperature часто даёт -127
  bool tempOk = (tC > -100 && tC < 125);

  // 2) Аналоговые датчики (с усреднением)
  int rawMoist = analogReadStable(PIN_MOIST, 12);
  int rawTds   = analogReadStable(PIN_TDS,   12);
  int rawPh    = analogReadStable(PIN_PH,    12);

  int moistPct = mapMoistPercent(rawMoist);

  float tdsPpm = calcTdsPpm(rawTds, tempOk ? tC : 25.0);
  float phApprox = calcPhApprox(rawPh);

  // 3) Формируем строку
  // RAW значения оставляем — это важно для демонстрации/калибровки
  String line = "";
  line += "TEMP:";
  line += (tempOk ? String(tC, 2) : String("NA"));
  line += ";PH_RAW:";
  line += String(rawPh);
  line += ";PH:";
  line += String(phApprox, 2);
  line += ";TDS_RAW:";
  line += String(rawTds);
  line += ";TDS:";
  line += String((int)tdsPpm);
  line += ";M_RAW:";
  line += String(rawMoist);
  line += ";M:";
  line += String(moistPct);

  // 4) Отправляем в USB Serial и Bluetooth
  Serial.println(line);
  bt.println(line);

  delay(2000);
}

