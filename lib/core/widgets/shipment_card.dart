import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../data/models/shipment.dart';
import '../utils/format.dart';
import 'app_card.dart';
import 'status_chip.dart';

class ShipmentCard extends StatelessWidget {
  final Shipment shipment;
  const ShipmentCard({super.key, required this.shipment});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.push('/track/${shipment.id}'),
      child: Row(
        children: [
          Container(
            height: 44,
            width: 44,
            decoration: BoxDecoration(
              color: Color(0x1F4F7F36),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.inventory_2_outlined, color: AppColors.green),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shipment.trackingId,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                SizedBox(height: 2),
                Text(
                  '${shipment.pickupAddress} \u2192 ${shipment.dropAddress}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                SizedBox(height: 2),
                Text(
                  formatDateTime(shipment.createdAt),
                  style: TextStyle(fontSize: 12, color: context.muted),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusChip(status: shipment.status),
              SizedBox(height: 6),
              Text(
                formatRs(shipment.price.round()),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
