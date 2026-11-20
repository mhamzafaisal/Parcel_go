import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../features/notifications/notification_providers.dart';

class NotificationBell extends ConsumerWidget {
  const NotificationBell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    return Container(
      decoration: BoxDecoration(
        color: context.surface,
        shape: BoxShape.circle,
        border: context.isDark ? Border.all(color: context.line) : null,
      ),
      child: IconButton(
        tooltip: 'Notifications',
        onPressed: () => context.push('/notifications'),
        icon: Badge(
          isLabelVisible: unread > 0,
          label: Text(unread > 9 ? '9+' : '$unread'),
          child: Icon(Icons.notifications_none, color: context.ink),
        ),
      ),
    );
  }
}
