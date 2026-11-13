import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_go/core/utils/format.dart';
import 'package:parcel_go/data/models/shipment.dart';
import 'package:parcel_go/data/services/shipment_filter.dart';

Shipment make(
  String id,
  ShipmentStatus status, {
  String receiver = 'Ali Khan',
  String pickup = 'Peoples Colony',
  String drop = 'D Ground',
}) =>
    Shipment(
      id: id,
      trackingId: id,
      customerId: 'c1',
      riderId: null,
      pickupAddress: pickup,
      dropAddress: drop,
      status: status,
      price: 290,
      createdAt: DateTime(2026, 11, 8),
      receiverName: receiver,
    );

void main() {
  final all = [
    make('PGAAA111', ShipmentStatus.created),
    make('PGBBB222', ShipmentStatus.assigned),
    make('PGCCC333', ShipmentStatus.pickedUp),
    make('PGDDD444', ShipmentStatus.inTransit),
    make('PGEEE555', ShipmentStatus.delivered, receiver: 'Sara Ahmed'),
    make('PGFFF666', ShipmentStatus.cancelled, drop: 'Model Town'),
  ];

  List<String> ids(List<Shipment> l) => l.map((s) => s.id).toList();

  test('filters by status group', () {
    expect(filterShipments(all, HistoryFilter.all, '').length, 6);
    expect(ids(filterShipments(all, HistoryFilter.active, '')),
        ['PGAAA111', 'PGBBB222', 'PGCCC333', 'PGDDD444']);
    expect(ids(filterShipments(all, HistoryFilter.delivered, '')),
        ['PGEEE555']);
    expect(ids(filterShipments(all, HistoryFilter.cancelled, '')),
        ['PGFFF666']);
  });

  test('search ignores case and spaces, checks id, name and addresses', () {
    expect(ids(filterShipments(all, HistoryFilter.all, '  pgbbb222 ')),
        ['PGBBB222']);
    expect(ids(filterShipments(all, HistoryFilter.all, 'sara')), ['PGEEE555']);
    expect(ids(filterShipments(all, HistoryFilter.all, 'model town')),
        ['PGFFF666']);
    expect(filterShipments(all, HistoryFilter.all, 'no such thing'), isEmpty);
  });

  test('search and filter work together', () {
    expect(filterShipments(all, HistoryFilter.active, 'sara'), isEmpty);
    expect(ids(filterShipments(all, HistoryFilter.delivered, 'sara')),
        ['PGEEE555']);
  });

  test('date group labels', () {
    final now = DateTime(2026, 11, 8, 0, 30);
    expect(dateGroupLabel(DateTime(2026, 11, 8, 0, 5), now), 'Today');
    expect(dateGroupLabel(DateTime(2026, 11, 7, 23, 50), now), 'Yesterday');
    expect(dateGroupLabel(DateTime(2026, 11, 5, 12, 0), now), '5 Nov 2026');
  });
}