import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/messenger.dart';
import '../../data/models/app_notification.dart';
import '../auth/auth_providers.dart';
import '../notifications/notification_actions.dart';
import 'notification_providers.dart';

/// App khuli ho aur naya notification aaye to neeche ek banner dikhata hai.
/// Pehli baar load hone wale purane notifications par banner nahi aata.
class NotificationToaster extends ConsumerStatefulWidget {
  final Widget child;
  const NotificationToaster({super.key, required this.child});

  @override
  ConsumerState<NotificationToaster> createState() =>
      _NotificationToasterState();
}

class _NotificationToasterState extends ConsumerState<NotificationToaster> {
  Set<String>? _seen;

  void _show(AppNotification n) {
    final messenger = rootMessengerKey.currentState;
    if (messenger == null) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 6),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(n.title, style: TextStyle(fontWeight: FontWeight.w700)),
              Text(n.body),
            ],
          ),
          action: SnackBarAction(
            label: 'View',
            onPressed: () => openNotification(ref, n),
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    // User badle (login ya logout) to dobara "pehli load" se shuru
    ref.listen<String?>(
      authStateProvider.select((a) => a.value?.uid),
      (prev, next) => _seen = null,
    );

    ref.listen<AsyncValue<List<AppNotification>>>(notificationsProvider, (
      prev,
      next,
    ) {
      if (next.isLoading) return;
      final list = next.value;
      if (list == null) return;

      final seen = _seen;
      _seen = list.map((n) => n.id).toSet();
      if (seen == null) return; // pehli load: banner nahi

      final fresh = list.where((n) => !n.read && !seen.contains(n.id)).toList();
      if (fresh.isNotEmpty) _show(fresh.first); // list nayi-pehle hai
    });

    return widget.child;
  }
}
