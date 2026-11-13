import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_go/data/models/rating.dart';

void main() {
  test('average and label from sum and count', () {
    const stats = RiderStats(sum: 9, count: 2);
    expect(stats.average, 4.5);
    expect(ratingLabel(stats), '4.5 (2)');
  });

  test('a rider with no ratings is "New"', () {
    expect(RiderStats.empty.average, isNull);
    expect(ratingLabel(RiderStats.empty), 'New');
  });

  test('star labels', () {
    expect(starLabel(1), 'Poor');
    expect(starLabel(3), 'Good');
    expect(starLabel(5), 'Excellent');
    expect(starLabel(0), '');
  });
}