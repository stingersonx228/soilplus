import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("О SoilPlus")),
      body: const Padding(
        padding: EdgeInsets.all(16),
        child: Text(
          "SoilPlus — оффлайн журнал замеров по участкам + рекомендации + инструменты.\n\n"
          "Bluetooth: скан → подключение → выбор характеристики → read/notify → автосохранение замера.",
        ),
      ),
    );
  }
}
