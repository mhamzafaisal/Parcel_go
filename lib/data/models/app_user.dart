import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:latlong2/latlong.dart';

enum UserRole { customer, rider }

class AppUser {
  final String uid;
  final String name;
  final String phone;
  final UserRole role;
  final bool isOnline;
  final double rating;
  final LatLng? location;
  final DateTime? locationAt;
  final String? activeJobId;

  const AppUser({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    this.isOnline = false,
    this.rating = 0,
    this.location,
    this.locationAt,
    this.activeJobId,
  });

  Map<String, dynamic> toCreateMap() => {
        'uid': uid,
        'name': name,
        'phone': phone,
        'role': role.name,
        'isOnline': false,
        'rating': 0,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory AppUser.fromMap(Map<String, dynamic> map) {
    final loc = map['location'];
    final at = map['locationAt'];
    return AppUser(
      uid: map['uid'] as String,
      name: map['name'] as String,
      phone: map['phone'] as String? ?? '',
      role: UserRole.values.byName(map['role'] as String),
      isOnline: map['isOnline'] as bool? ?? false,
      rating: (map['rating'] as num?)?.toDouble() ?? 0,
      location: loc is Map
          ? LatLng((loc['lat'] as num).toDouble(), (loc['lng'] as num).toDouble())
          : null,
      locationAt: at is Timestamp ? at.toDate() : null,
      activeJobId: map['activeJobId'] as String?,
    );
  }
}