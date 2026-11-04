import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/parcel_options.dart';
import '../../../data/services/pricing_service.dart';
import 'shipment_draft.dart';

class ShipmentSummaryScreen extends ConsumerWidget {
  const ShipmentSummaryScreen({super.key});

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(shipmentDraftProvider);
    final pickup = draft.pickup;
    final drop = draft.drop;
    final weight = draft.weightKg;

    // Page refresh ke baad draft khali ho jata hai
    if (pickup == null || drop == null || weight == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review and price')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please fill in your shipment details first.'),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Start again',
                  onPressed: () => context.go('/create-shipment'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final straightKm =
        const Distance().as(LengthUnit.Kilometer, pickup.latLng, drop.latLng);
    final inRange = PricingService.isInRange(straightKm);

    PriceBreakdown quote(DeliverySpeed s) => PricingService.calculate(
          straightKm: straightKm,
          size: draft.size,
          weightKg: weight,
          fragile: draft.fragile,
          speed: s,
        );

    final selected = quote(draft.speed);

    return Scaffold(
      appBar: AppBar(title: const Text('Review and price')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Route
            AppCard(
              child: Row(
                children: [
                  const Column(
                    children: [
                      Icon(Icons.radio_button_checked,
                          size: 18, color: AppColors.green),
                      SizedBox(height: 6),
                      Icon(Icons.location_on,
                          size: 18, color: AppColors.danger),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(pickup.address,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 8),
                        Text(drop.address,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (!inRange) ...[
              AppCard(
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber, color: AppColors.danger),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'This is too far for city delivery (limit ${PricingService.maxDistanceKm.round()} km). '
                        'Please go back and choose closer locations.',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Go back',
                icon: Icons.arrow_back,
                onPressed: () => context.pop(),
              ),
            ] else ...[
              // Speed
              Text('Delivery speed',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final s in DeliverySpeed.values) ...[
                    Expanded(
                      child: _SpeedCard(
                        speed: s,
                        quote: quote(s),
                        selected: draft.speed == s,
                        onTap: () => ref
                            .read(shipmentDraftProvider.notifier)
                            .setSpeed(s),
                      ),
                    ),
                    if (s != DeliverySpeed.values.last)
                      const SizedBox(width: 12),
                  ],
                ],
              ),
              const SizedBox(height: 24),

              // Parcel
              Text('Parcel', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (draft.photo != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(draft.photo!,
                            height: 64, width: 64, fit: BoxFit.cover),
                      ),
                      const SizedBox(width: 14),
                    ],
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${draft.category.label}  \u2022  ${draft.size.label}  \u2022  $weight kg'
                            '${draft.fragile ? '  \u2022  Fragile' : ''}',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                              'To: ${draft.receiverName} (${draft.receiverPhone})'),
                          if (draft.notes.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text('Note: ${draft.notes}',
                                style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Price
              Text('Price', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              AppCard(
                child: Column(
                  children: [
                    for (final line in selected.lines)
                      _PriceRow(label: line.label, amount: line.amount),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: AppColors.border),
                    ),
                    _PriceRow(
                        label: 'Total', amount: selected.total, bold: true),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Estimated price. Distance is estimated from the map.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Continue to payment',
                onPressed: () => context.push('/payment'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final int amount;
  final bool bold;

  const _PriceRow({
    required this.label,
    required this.amount,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 18 : 14,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: bold ? AppColors.green : AppColors.textDark,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(formatRs(amount), style: style),
        ],
      ),
    );
  }
}

class _SpeedCard extends StatelessWidget {
  final DeliverySpeed speed;
  final PriceBreakdown quote;
  final bool selected;
  final VoidCallback onTap;

  const _SpeedCard({
    required this.speed,
    required this.quote,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0x143F5B2E) : AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.green : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              speed == DeliverySpeed.express
                  ? Icons.bolt
                  : Icons.local_shipping_outlined,
              color: AppColors.green,
            ),
            const SizedBox(height: 8),
            Text(speed.label,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 2),
            Text('About ${formatEta(quote.etaMinutes)}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Text(formatRs(quote.total),
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.green)),
          ],
        ),
      ),
    );
  }
}