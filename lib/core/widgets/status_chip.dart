import 'package:flutter/material.dart';
import '../../app/theme.dart';
import '../../data/models/shipment.dart';

class StatusChip extends StatelessWidget {
  final ShipmentStatus status;
  const StatusChip({super.key, required this.status});

  Color get _fg {
    switch (status) {
      case ShipmentStatus.delivered:
        return AppColors.green;
      case ShipmentStatus.cancelled:
        return AppColors.danger;
      case ShipmentStatus.created:
        return AppColors.textMuted;
      default:
        return const Color(0xFFB7791F);
    }
  }

  Color get _bg {
    switch (status) {
      case ShipmentStatus.delivered:
        return const Color(0x1F3F5B2E);
      case ShipmentStatus.cancelled:
        return const Color(0x1FC0492F);
      case ShipmentStatus.created:
        return const Color(0x1F6B7566);
      default:
        return const Color(0x1FB7791F);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status.label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: _fg)),
    );
  }
}