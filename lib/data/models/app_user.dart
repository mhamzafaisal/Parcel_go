import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { customer, rider }

class AppUser {
  final String uid;
  final String name;
  final String phone;
  final UserRole role;
  final bool isOnline;
  final double rating;

  const AppUser({
    required this.uid,
    required this.name,
    required this.phone,
    required this.role,
    this.isOnline = false,
    this.rating = 0,
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

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        uid: map['uid'] as String,
        name: map['name'] as String,
        phone: map['phone'] as String? ?? '',
        role: UserRole.values.byName(map['role'] as String),
        isOnline: map['isOnline'] as bool? ?? false,
        rating: (map['rating'] as num?)?.toDouble() ?? 0,
      );
}