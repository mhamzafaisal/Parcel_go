import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/router.dart';
import '../../data/models/app_notification.dart';
import '../../data/repositories/notification_repository.dart';

/// Notification kholna: padha hua nishan lagao aur sahi screen par jao
void openNotification(WidgetRef ref, AppNotification n) {
  if (!n.read) {
    ref
        .read(notificationRepositoryProvider)
        .markRead(n.id)
        .catchError((Object e) => debugPrint('Mark read failed: $e'));
  }
  final router = ref.read(routerProvider);
  if (n.kind == 'rating') {
    router.go('/rider-profile');
  } else {
    router.push('/track/${n.shipmentId}');
  }
}