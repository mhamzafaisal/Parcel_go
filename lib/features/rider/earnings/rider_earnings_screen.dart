import 'package:flutter/material.dart';

class RiderEarningsScreen extends StatelessWidget {
  const RiderEarningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Earnings')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Earnings and payout history come in Task 27',
              textAlign: TextAlign.center),
        ),
      ),
    );
  }
}