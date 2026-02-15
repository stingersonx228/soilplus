import 'package:flutter/material.dart';

class KvRow extends StatelessWidget {
  final String k;
  final String v;
  const KvRow({super.key, required this.k, required this.v});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text("$k: ", style: const TextStyle(fontWeight: FontWeight.w600)),
        Expanded(child: Text(v)),
      ],
    );
  }
}
