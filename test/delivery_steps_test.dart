import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_go/data/models/delivery_steps.dart';
import 'package:parcel_go/data/models/shipment.dart';

List<StepState> states(ShipmentStatus s) =>
    buildDeliverySteps(s).map((e) => e.state).toList();

void main() {
  test('just assigned: pickup is the current step', () {
    expect(states(ShipmentStatus.assigned), [
      StepState.done,
      StepState.current,
      StepState.upcoming,
      StepState.upcoming,
    ]);
  });

  test('picked up: on the way is current', () {
    expect(states(ShipmentStatus.pickedUp), [
      StepState.done,
      StepState.done,
      StepState.current,
      StepState.upcoming,
    ]);
  });

  test('in transit: delivery is current', () {
    expect(states(ShipmentStatus.inTransit), [
      StepState.done,
      StepState.done,
      StepState.done,
      StepState.current,
    ]);
  });

  test('delivered: everything is done', () {
    expect(states(ShipmentStatus.delivered),
        List.filled(4, StepState.done));
  });

  test('target is pickup before pickup, drop after', () {
    expect(deliveryTarget(ShipmentStatus.assigned), DeliveryTarget.pickup);
    expect(deliveryTarget(ShipmentStatus.pickedUp), DeliveryTarget.drop);
    expect(deliveryTarget(ShipmentStatus.inTransit), DeliveryTarget.drop);
  });

  test('button label follows the status', () {
    expect(nextActionLabel(ShipmentStatus.assigned),
        'I have picked up the parcel');
    expect(nextActionLabel(ShipmentStatus.pickedUp), 'Start trip');
    expect(nextActionLabel(ShipmentStatus.delivered), isNull);
  });
}