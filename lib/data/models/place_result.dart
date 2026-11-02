import 'package:latlong2/latlong.dart';

class PlaceResult {
  final String address;
  final double latitude;
  final double longitude;

  const PlaceResult({
    required this.address,
    required this.latitude,
    required this.longitude,
  });

  LatLng get latLng => LatLng(latitude, longitude);

  /// Firestore mein save karne ke liye (Task 16)
  Map<String, dynamic> toMap() => {
        'address': address,
        'lat': latitude,
        'lng': longitude,
      };
}