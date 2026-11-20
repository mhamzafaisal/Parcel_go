import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../data/models/shipment.dart';

class StatusChip extends StatelessWidget {
  final ShipmentStatus status;
  const StatusChip({super.key, required this.status});

  Color _color(BuildContext context) {
    switch (status) {
      case ShipmentStatus.delivered:
        return AppColors.green;
      case ShipmentStatus.cancelled:
        return AppColors.danger;
      case ShipmentStatus.created:
        return context.muted;
      default:
        return Color(0xFFB7791F);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color(context);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(0x26),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
