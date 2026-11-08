import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message)));
}

/// Google Maps mein rasta kholta hai (API key nahi chahiye)
Future<void> openDirections(BuildContext context, LatLng target) async {
  final uri = Uri.https('www.google.com', '/maps/dir/', {
    'api': '1',
    'destination': '${target.latitude},${target.longitude}',
    'travelmode': 'driving',
  });
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) _snack(context, 'Could not open Maps.');
  } catch (_) {
    if (context.mounted) _snack(context, 'Could not open Maps.');
  }
}

Future<void> callNumber(BuildContext context, String phone) async {
  try {
    final ok = await launchUrl(Uri(scheme: 'tel', path: phone));
    if (!ok && context.mounted) _snack(context, 'Could not open the dialer.');
  } catch (_) {
    if (context.mounted) _snack(context, 'Could not open the dialer.');
  }
}