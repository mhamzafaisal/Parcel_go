import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: ParcelGoApp()));
}

class ParcelGoApp extends StatelessWidget {
  const ParcelGoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ParcelGo',
      debugShowCheckedModeBanner: false,
      home: const Scaffold(
        body: Center(child: Text('ParcelGo is running')),
      ),
    );
  }
}