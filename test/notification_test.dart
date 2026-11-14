import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_go/data/models/app_notification.dart';
import 'package:parcel_go/data/models/shipment.dart';

void main() {
  test('status titles match the wording the rules expect', () {
    expect(statusNotificationTitle(ShipmentStatus.assigned), 'Rider assigned');
    expect(statusNotificationTitle(ShipmentStatus.pickedUp), 'Parcel picked up');
    expect(statusNotificationTitle(ShipmentStatus.inTransit), 'Parcel on the way');
    expect(statusNotificationTitle(ShipmentStatus.delivered), 'Parcel delivered');
  });

  test('status notification has a fixed id, body and recipient', () {
    expect(statusNotificationId('PGABC2345', ShipmentStatus.pickedUp),
        'PGABC2345_picked_up');
    final data = statusNotificationData(
      userId: 'customer1',
      shipmentId: 'PGABC2345',
      status: ShipmentStatus.pickedUp,
    );
    expect(data['userId'], 'customer1');
    expect(data['kind'], 'picked_up');
    expect(data['title'], 'Parcel picked up');
    expect(data['body'], 'Tracking ID PGABC2345');
    expect(data['read'], false);
  });

  test('rating notification goes to the rider with fixed text', () {
    expect(ratingNotificationId('PGABC2345'), 'PGABC2345_rating');
    final data =
        ratingNotificationData(userId: 'rider1', shipmentId: 'PGABC2345');
    expect(data['userId'], 'rider1');
    expect(data['kind'], 'rating');
    expect(data['title'], 'New rating');
    expect(data['body'], 'You received a new rating');
  });
}