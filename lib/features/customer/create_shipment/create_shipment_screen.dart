import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/place_result.dart';
import 'location_picker_screen.dart';
import 'shipment_draft.dart';

class CreateShipmentScreen extends ConsumerWidget {
  const CreateShipmentScreen({super.key});

  Future<void> _pick(BuildContext context, WidgetRef ref,
      {required bool pickup}) async {
    final draft = ref.read(shipmentDraftProvider);
    final result = await context.push<PlaceResult>(
      '/pick-location',
      extra: PickerArgs(
        title: pickup ? 'Pickup location' : 'Drop location',
        initial: pickup ? draft.pickup : draft.drop,
      ),
    );
    if (result == null) return;
    final notifier = ref.read(shipmentDraftProvider.notifier);
    if (pickup) {
      notifier.setPickup(result);
    } else {
      notifier.setDrop(result);
    }
  }

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

    double? km;
    if (pickup != null && drop != null) {
      km = const Distance().as(LengthUnit.Kilometer, pickup.latLng, drop.latLng);
    }
    final tooClose = km != null && km < 0.05;

    return Scaffold(
      appBar: AppBar(title: const Text('Send a parcel')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Where should we deliver?',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text('Choose pickup and drop locations on the map.',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 20),
            AppCard(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  _AddressTile(
                    icon: Icons.radio_button_checked,
                    iconColor: AppColors.green,
                    label: 'Pickup',
                    value: pickup?.address,
                    hint: 'Choose pickup location',
                    onTap: () => _pick(context, ref, pickup: true),
                  ),
                  Row(
                    children: [
                      const SizedBox(width: 12),
                      const Expanded(
                          child: Divider(height: 1, color: AppColors.border)),
                      IconButton(
                        tooltip: 'Swap',
                        onPressed: (pickup == null && drop == null)
                            ? null
                            : ref.read(shipmentDraftProvider.notifier).swap,
                        icon: const Icon(Icons.swap_vert,
                            color: AppColors.green),
                      ),
                    ],
                  ),
                  _AddressTile(
                    icon: Icons.location_on,
                    iconColor: AppColors.danger,
                    label: 'Drop',
                    value: drop?.address,
                    hint: 'Choose drop location',
                    onTap: () => _pick(context, ref, pickup: false),
                  ),
                ],
              ),
            ),
            if (km != null) ...[
              const SizedBox(height: 16),
              AppCard(
                child: Row(
                  children: [
                    Icon(tooClose ? Icons.warning_amber : Icons.route,
                        color: tooClose ? AppColors.danger : AppColors.green),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tooClose
                            ? 'Pickup and drop are too close. Please choose different places.'
                            : 'About ${km.toStringAsFixed(1)} km (straight line)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            PrimaryButton(
              label: 'Continue',
              onPressed: () {
                if (pickup == null || drop == null) {
                  _snack(context, 'Please choose both locations');
                } else if (tooClose) {
                  _snack(context, 'Pickup and drop are too close');
                } else {
                  _snack(context, 'Locations saved. Parcel details come in Task 12.');
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AddressTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? value;
  final String hint;
  final VoidCallback onTap;

  const _AddressTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.hint,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(icon, color: iconColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text(
                    value ?? hint,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          value == null ? FontWeight.w400 : FontWeight.w600,
                      color: value == null
                          ? AppColors.textMuted
                          : AppColors.textDark,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}