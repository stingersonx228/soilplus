import 'package:flutter/material.dart';
import 'plots_screen.dart';
import 'irrigation_calc_screen.dart';
import 'about_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  int idx = 0;

  final pages = const [
    PlotsScreen(),
    IrrigationCalcScreen(),
    AboutScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: pages[idx],
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (v) => setState(() => idx = v),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.map_outlined), label: "Участки"),
          NavigationDestination(icon: Icon(Icons.water_drop_outlined), label: "Орошение"),
          NavigationDestination(icon: Icon(Icons.info_outline), label: "О приложении"),
        ],
      ),
    );
  }
}
