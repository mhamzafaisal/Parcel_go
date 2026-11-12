import 'delivery_steps.dart';
import 'shipment.dart';
import 'shipment_event.dart';

class TimelineEntry {
  final String title;
  final DateTime? at;
  final StepState state;
  const TimelineEntry(this.title, this.at, this.state);
}

const _steps = [
  (ShipmentStatus.created, 'Booking confirmed'),
  (ShipmentStatus.assigned, 'Rider assigned'),
  (ShipmentStatus.pickedUp, 'Parcel picked up'),
  (ShipmentStatus.inTransit, 'On the way'),
  (ShipmentStatus.delivered, 'Delivered'),
];

int _rank(ShipmentStatus s) => switch (s) {
      ShipmentStatus.created => 1,
      ShipmentStatus.assigned => 2,
      ShipmentStatus.pickedUp => 3,
      ShipmentStatus.inTransit => 4,
      ShipmentStatus.delivered => 5,
      ShipmentStatus.cancelled => 0,
    };

/// Customer ke liye timeline. "Kitna aage badha" status se tay hota hai,
/// waqt events se aata hai (event na ho to waqt khali rehta hai).
List<TimelineEntry> buildTimeline(
  ShipmentStatus status,
  List<ShipmentEvent> events,
) {
  final reached = _rank(status);
  final cancelled = status == ShipmentStatus.cancelled;
  final timeOf = <ShipmentStatus, DateTime>{
    for (final e in events) e.status: e.at,
  };

  var currentFound = false;
  final result = <TimelineEntry>[];
  for (var i = 0; i < _steps.length; i++) {
    final (stepStatus, title) = _steps[i];
    final at = timeOf[stepStatus];

    final StepState state;
    if (cancelled ? at != null : reached >= i + 1) {
      state = StepState.done;
    } else if (!cancelled && !currentFound) {
      state = StepState.current;
      currentFound = true;
    } else {
      state = StepState.upcoming;
    }
    result.add(TimelineEntry(title, at, state));
  }
  return result;
}