import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/saved_address.dart';
import '../../data/repositories/address_repository.dart';
import '../auth/auth_providers.dart';

final savedAddressesProvider = StreamProvider<List<SavedAddress>>((ref) {
  final uid = ref.watch(authStateProvider.select((a) => a.value?.uid));
  if (uid == null) return Stream.value(const <SavedAddress>[]);
  return ref.watch(addressRepositoryProvider).watch(uid);
});
