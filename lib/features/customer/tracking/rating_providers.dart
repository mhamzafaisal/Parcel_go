import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/rating.dart';
import '../../../data/repositories/rating_repository.dart';

final ratingProvider = StreamProvider.family<Rating?, String>((ref, shipmentId) {
  return ref.watch(ratingRepositoryProvider).watchRating(shipmentId);
});