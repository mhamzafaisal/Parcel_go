import 'package:flutter/material.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ParcelGo')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Send a parcel',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          PrimaryButton(
              label: 'Send now', icon: Icons.send_outlined, onPressed: () {}),
          const SizedBox(height: 24),
          const AppCard(
            child: Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: AppColors.green),
                SizedBox(width: 12),
                Expanded(child: Text('Recent shipments will appear here')),
              ],
            ),
          ),
        ],
      ),
    );
  }
}