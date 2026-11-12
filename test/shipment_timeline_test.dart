import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_go/data/models/delivery_steps.dart';
import 'package:parcel_go/data/models/shipment.dart';
import 'package:parcel_go/data/models/shipment_event.dart';
import 'package:parcel_go/data/models/shipment_timeline.dart';

List<StepState> states(List<TimelineEntry> t) =>
    t.map((e) => e.state).toList();

void main() {
  final t1 = DateTime(2026, 11, 8, 10, 0);
  final t2 = DateTime(2026, 11, 8, 10, 5);
  final t3 = DateTime(2026, 11, 8, 10, 40);
  final t4 = DateTime(2026, 11, 8, 10, 50);

  test('just booked: waiting for a rider', () {
    final t = buildTimeline(ShipmentStatus.created, [
      ShipmentEvent(status: ShipmentStatus.created, at: t1),
    ]);
    expect(states(t), [
      StepState.done,
      StepState.current,
      StepState.upcoming,
      StepState.upcoming,
      StepState.upcoming,
    ]);
    expect(t.first.at, t1);
  });

  test('in transit: four steps done, delivery is current', () {
    final t = buildTimeline(ShipmentStatus.inTransit, [
      ShipmentEvent(status: ShipmentStatus.created, at: t1),
      ShipmentEvent(status: ShipmentStatus.assigned, at: t2),
      ShipmentEvent(status: ShipmentStatus.pickedUp, at: t3),
      ShipmentEvent(status: ShipmentStatus.inTransit, at: t4),
    ]);
    expect(states(t), [
      StepState.done,
      StepState.done,
      StepState.done,
      StepState.done,
      StepState.current,
    ]);
    expect(t[3].at, t4);
    expect(t.last.at, isNull);
  });

  test('delivered: everything is done', () {
    final t = buildTimeline(ShipmentStatus.delivered, []);
    expect(states(t), List.filled(5, StepState.done));
  });

  test('missing events do not break the steps, only the times', () {
    final t = buildTimeline(ShipmentStatus.inTransit, []);
    expect(states(t).take(4), everyElement(StepState.done));
    expect(t.first.at, isNull);
  });

  test('cancelled: only steps with an event are done, nothing is current', () {
    final t = buildTimeline(ShipmentStatus.cancelled, [
      ShipmentEvent(status: ShipmentStatus.created, at: t1),
    ]);
    expect(states(t), [
      StepState.done,
      StepState.upcoming,
      StepState.upcoming,
      StepState.upcoming,
      StepState.upcoming,
    ]);
  });
}