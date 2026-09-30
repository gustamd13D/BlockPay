import 'package:flutter/material.dart';
import 'telas/tela_inicial.dart';

void main() {
  runApp(const BlockPayApp());
}

class BlockPayApp extends StatelessWidget {
  const BlockPayApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'BlockPay',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0B0E17),
      ),
      home: const TelaInicial(),
    );
  }
}

