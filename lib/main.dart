import 'package:flutter/material.dart';

void main() {
  runApp(const CuentasClarasApp());
}

class CuentasClarasApp extends StatelessWidget {
  const CuentasClarasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Cuentas Claras',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Cuentas Claras'),
        ),
        body: const Center(
          child: Text(
            'Bienvenido a Cuentas Claras',
            style: TextStyle(fontSize: 22),
          ),
        ),
      ),
    );
  }
}