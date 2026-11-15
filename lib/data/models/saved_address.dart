import 'package:cloud_firestore/cloud_firestore.dart';

import 'place_result.dart';

const int kMaxSavedAddresses = 10;

class SavedAddress {
  final String id;
  final String label;
  final PlaceResult place;
  final DateTime createdAt;

  const SavedAddress({
    required this.id,
    required this.label,
    required this.place,
    required this.createdAt,
  });

  factory SavedAddress.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'];
    return SavedAddress(
      id: doc.id,
      label: d['label'] as String? ?? '',
      place: PlaceResult(
        address: d['address'] as String? ?? '-',
        latitude: (d['lat'] as num?)?.toDouble() ?? 0,
        longitude: (d['lng'] as num?)?.toDouble() ?? 0,
      ),
      // Naye likhe gaye document mein server time kuch pal null hota hai
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}

/// Address ke label ki jaanch. Theek ho to null.
String? validateAddressLabel(String? value) {
  final v = (value ?? '').trim();
  if (v.isEmpty) return 'Enter a label, e.g. Home';
  if (v.length > 20) return 'Keep it under 20 letters';
  return null;
}

/// Naam ki jaanch (2 se 40 harf). Theek ho to null.
String? validatePersonName(String? value) {
  final v = (value ?? '').trim();
  if (v.length < 2) return 'Please enter your name';
  if (v.length > 40) return 'Keep it under 40 letters';
  return null;
}
