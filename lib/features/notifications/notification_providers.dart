import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/app_notification.dart';
import '../../data/repositories/notification_repository.dart';
import '../auth/auth_providers.dart';

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final uid = ref.watch(authStateProvider.select((a) => a.value?.uid));
  if (uid == null) return Stream.value(const <AppNotification>[]);
  return ref.watch(notificationRepositoryProvider).watchForUser(uid);
});

final unreadCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsProvider).value;
  if (list == null) return 0;
  return list.where((n) => !n.read).length;
});