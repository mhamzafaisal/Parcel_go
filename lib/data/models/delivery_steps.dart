import 'shipment.dart';

enum StepState { done, current, upcoming }
enum DeliveryTarget { pickup, drop }

class DeliveryStep {
  final String title;
  final String instruction;
  final StepState state;
  const DeliveryStep(this.title, this.instruction, this.state);
}

/// Status kitna aage badha hai (0 = abhi shuru nahi)
int _rank(ShipmentStatus s) {
  switch (s) {
    case ShipmentStatus.assigned:
      return 1;
    case ShipmentStatus.pickedUp:
      return 2;
    case ShipmentStatus.inTransit:
      return 3;
    case ShipmentStatus.delivered:
      return 4;
    case ShipmentStatus.created:
    case ShipmentStatus.cancelled:
      return 0;
  }
}

List<DeliveryStep> buildDeliverySteps(ShipmentStatus status) {
  const steps = [
    ('Parcel accepted', 'You are assigned to this parcel'),
    ('Picked up', 'Go to the pickup location and collect the parcel'),
    ('On the way', 'Take the parcel to the drop location'),
    ('Delivered', 'Hand over to the receiver and enter the delivery code'),
  ];
  final reached = _rank(status);
  var currentFound = false;
  final result = <DeliveryStep>[];
  for (var i = 0; i < steps.length; i++) {
    final StepState state;
    if (reached >= i + 1) {
      state = StepState.done;
    } else if (!currentFound) {
      state = StepState.current;
      currentFound = true;
    } else {
      state = StepState.upcoming;
    }
    result.add(DeliveryStep(steps[i].$1, steps[i].$2, state));
  }
  return result;
}

/// Rider ko abhi kahan jana hai
DeliveryTarget deliveryTarget(ShipmentStatus status) {
  switch (status) {
    case ShipmentStatus.created:
    case ShipmentStatus.assigned:
      return DeliveryTarget.pickup;
    default:
      return DeliveryTarget.drop;
  }
}

/// Agla button kya kahe (Task 19 mein kaam karega)
String? nextActionLabel(ShipmentStatus status) {
  switch (status) {
    case ShipmentStatus.assigned:
      return 'I have picked up the parcel';
    case ShipmentStatus.pickedUp:
      return 'Start trip';
    case ShipmentStatus.inTransit:
      return 'Hand over parcel';
    default:
      return null;
  }
}