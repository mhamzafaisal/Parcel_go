import '../models/shipment.dart';

enum HistoryFilter {
  all('All'),
  active('Active'),
  delivered('Delivered'),
  cancelled('Cancelled');

  final String label;
  const HistoryFilter(this.label);
}

bool matchesFilter(Shipment s, HistoryFilter f) {
  switch (f) {
    case HistoryFilter.all:
      return true;
    case HistoryFilter.active:
      return s.status == ShipmentStatus.created ||
          s.status == ShipmentStatus.assigned ||
          s.status == ShipmentStatus.pickedUp ||
          s.status == ShipmentStatus.inTransit;
    case HistoryFilter.delivered:
      return s.status == ShipmentStatus.delivered;
    case HistoryFilter.cancelled:
      return s.status == ShipmentStatus.cancelled;
  }
}

/// Filter aur search ke baad ki list (tarteeb wahi jo di gayi)
List<Shipment> filterShipments(
  List<Shipment> list,
  HistoryFilter filter,
  String query,
) {
  final q = query.trim().toLowerCase();
  return list.where((s) {
    if (!matchesFilter(s, filter)) return false;
    if (q.isEmpty) return true;
    return s.trackingId.toLowerCase().contains(q) ||
        s.receiverName.toLowerCase().contains(q) ||
        s.pickupAddress.toLowerCase().contains(q) ||
        s.dropAddress.toLowerCase().contains(q);
  }).toList();
}