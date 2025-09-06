import 'package:flutter/material.dart';
import 'bluetoothControlApp.dart';
void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App Điều Khiển LED',
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.blue,
          title: const Text('App Điều Khiển LED')
        ),
        body: BluetoothControlApp()
      ),
    );
  }
}