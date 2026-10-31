import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/theme.dart';
import 'core/widgets/app_card.dart';
import 'core/widgets/app_text_field.dart';
import 'core/widgets/primary_button.dart';

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
      theme: AppTheme.light,
      home: const WidgetPreview(),
    );
  }
}

class WidgetPreview extends StatelessWidget {
  const WidgetPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ParcelGo')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Track your parcel',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          const AppTextField(
            label: 'Tracking ID',
            hint: 'Enter tracking ID',
            icon: Icons.local_shipping_outlined,
          ),
          const SizedBox(height: 16),
          PrimaryButton(label: 'Track', icon: Icons.search, onPressed: () {}),
          const SizedBox(height: 24),
          AppCard(
            onTap: () {},
            child: const Row(
              children: [
                Icon(Icons.inventory_2_outlined, color: AppColors.green),
                SizedBox(width: 12),
                Expanded(child: Text('Parcel #PG1024 - In transit')),
                Icon(Icons.chevron_right),
              ],
            ),
          ),
        ],
      ),
    );
  }
}