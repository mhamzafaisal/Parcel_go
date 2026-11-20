import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_card.dart';
import '../../data/models/app_notification.dart';
import '../../data/repositories/notification_repository.dart';
import 'notification_actions.dart';
import 'notification_providers.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  IconData _icon(String kind) {
    switch (kind) {
      case 'assigned':
        return Icons.two_wheeler;
      case 'picked_up':
        return Icons.inventory_2_outlined;
      case 'in_transit':
        return Icons.local_shipping_outlined;
      case 'delivered':
        return Icons.check_circle_outline;
      case 'rating':
        return Icons.star_outline_rounded;
      default:
        return Icons.notifications_none;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    final unread = ref.watch(unreadCountProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: Text('Notifications'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () {
                final ids = (notifications.value ?? const <AppNotification>[])
                    .where((n) => !n.read)
                    .map((n) => n.id)
                    .toList();
                ref.read(notificationRepositoryProvider).markAllRead(ids);
              },
              child: Text(
                'Mark all read',
                style: TextStyle(color: AppColors.green),
              ),
            ),
        ],
      ),
      body: notifications.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Could not load notifications. Check your internet.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 56,
                      color: context.muted,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'No notifications yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Updates about your parcels will show up here.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            );
          }
          return ListView.separated(
            padding: EdgeInsets.all(20),
            itemCount: list.length,
            separatorBuilder: (_, _) => SizedBox(height: 12),
            itemBuilder: (context, i) {
              final n = list[i];
              return AppCard(
                onTap: () => openNotification(ref, n),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 42,
                      width: 42,
                      decoration: BoxDecoration(
                        color: n.read ? context.chip : Color(0x1F4F7F36),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(_icon(n.kind), color: AppColors.green),
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: n.read
                                  ? FontWeight.w500
                                  : FontWeight.w800,
                              color: context.ink,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            n.body,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          SizedBox(height: 4),
                          Text(
                            timeAgo(n.createdAt, now),
                            style: TextStyle(
                              fontSize: 12,
                              color: context.muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (!n.read)
                      const Padding(
                        padding: EdgeInsets.only(top: 6, left: 8),
                        child: Icon(
                          Icons.circle,
                          size: 10,
                          color: AppColors.green,
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
