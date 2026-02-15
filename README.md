# SoilPlus 🌱  
**Smart offline irrigation assistant for farmers**

---

## 🇷🇺 О проекте

**SoilPlus** — это мобильное приложение для расчёта и планирования полива,  
работающее **полностью оффлайн** и поддерживающее подключение  
к BLE-датчикам влажности почвы.

Проект создан как **MVP агротех-решения** для:

- фермеров без стабильного интернета  
- теплиц и небольших хозяйств  
- учебных и исследовательских задач  

### Возможности

- 📊 Расчёт нормы полива по формуле **ET₀ × Kc**
- 🌾 Выбор культуры и стадии роста
- 💧 Учёт осадков и эффективности системы
- 🗓 Недельный план полива
- 🧠 Профили участков с сохранением параметров
- 📡 Подготовка к работе с **BLE-датчиками влажности**
- 🔌 Полностью **оффлайн-режим**

---

## 🇬🇧 About the project

**SoilPlus** is a mobile irrigation planning app designed to work  
**fully offline** and integrate with **BLE soil moisture sensors**.

It is built as an **AgriTech MVP** for:

- farmers with limited internet access  
- greenhouses and small farms  
- educational and research use  

### Features

- 📊 Irrigation calculation using **ET₀ × Kc**
- 🌾 Crop and growth stage selection
- 💧 Rainfall and system efficiency adjustment
- 🗓 Weekly irrigation planning
- 🧠 Plot profiles with saved parameters
- 📡 Ready for **BLE soil sensor integration**
- 🔌 Works completely **offline**

---

## 🛠 Tech stack

- **Flutter (Dart)**
- Local offline storage
- BLE integration (in progress)
- Android first

---

## 🚀 Roadmap

- [x] Offline irrigation calculator  
- [x] Plot profiles  
- [x] Weekly irrigation plan  
- [ ] BLE soil moisture auto-sync  
- [ ] Irrigation recommendations from real sensor data  
- [ ] Cloud sync & farmer accounts  

---

## 📦 Build

```bash
flutter build apk --release
