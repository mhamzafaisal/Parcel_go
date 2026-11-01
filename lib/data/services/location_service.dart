import 'package:geolocator/geolocator.dart';

enum LocationIssue { serviceOff, denied, deniedForever }

class LocationException implements Exception {
  final LocationIssue issue;
  const LocationException(this.issue);

  String get message {
    switch (issue) {
      case LocationIssue.serviceOff:
        return 'Location is turned off. Please turn it on.';
      case LocationIssue.denied:
        return 'Location permission is needed to find where you are.';
      case LocationIssue.deniedForever:
        return 'Location permission is blocked. Please allow it in settings.';
    }
  }
}

class LocationService {
  static Future<Position> getCurrentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) throw const LocationException(LocationIssue.serviceOff);

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw const LocationException(LocationIssue.denied);
    }
    if (permission == LocationPermission.deniedForever) {
      throw const LocationException(LocationIssue.deniedForever);
    }

    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 15),
      ),
    );
  }

  static Future<void> openAppSettings() => Geolocator.openAppSettings();
  static Future<void> openLocationSettings() =>
      Geolocator.openLocationSettings();
}