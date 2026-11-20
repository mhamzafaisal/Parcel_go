import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import 'job_providers.dart';

import 'package:go_router/go_router.dart';

class ActiveJobCard extends ConsumerWidget {
  const ActiveJobCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final shipment = ref.watch(activeShipmentProvider);

    return shipment.when(
      loading: () => AppCard(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(12),
            child: CircularProgressIndicator(),
          ),
        ),
      ),
      error: (e, _) => AppCard(child: Text('Could not load your delivery.')),
      data: (s) {
        if (s == null) {
          return AppCard(child: Text('Your delivery could not be found.'));
        }
        return AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Active delivery',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  StatusChip(status: s.status),
                ],
              ),
              SizedBox(height: 6),
              Text(
                s.trackingId,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2,
                  color: AppColors.green,
                ),
              ),
              SizedBox(height: 14),
              Row(
                children: [
                  Icon(
                    Icons.radio_button_checked,
                    size: 18,
                    color: AppColors.green,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.pickupAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.location_on, size: 18, color: AppColors.danger),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.dropAddress,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Divider(height: 1, color: context.line),
              ),
              Row(
                children: [
                  Icon(Icons.person_outline, color: context.muted),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      s.receiverName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.phone_outlined, color: context.muted),
                  SizedBox(width: 10),
                  Expanded(child: Text(s.receiverPhone)),
                ],
              ),
              if (s.notes.isNotEmpty) ...[
                SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.sticky_note_2_outlined, color: context.muted),
                    SizedBox(width: 10),
                    Expanded(child: Text(s.notes)),
                  ],
                ),
              ],
              SizedBox(height: 16),
              PrimaryButton(
                label: 'Continue delivery',
                icon: Icons.navigation_outlined,
                onPressed: () {
                  context.push('/rider-delivery');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
