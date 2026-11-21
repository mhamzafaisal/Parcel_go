import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../data/services/connectivity_service.dart';

/// Internet jaye to app ke upar laal patti.
class ConnectivityBanner extends ConsumerWidget {
  final Widget child;
  const ConnectivityBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final online = ref.watch(isOnlineProvider).value ?? true;

    return Column(
      children: [
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          child: online
              ? const SizedBox(width: double.infinity)
              : Material(
                  color: AppColors.danger,
                  child: SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.wifi_off,
                            size: 16,
                            color: AppColors.white,
                          ),
                          SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'You are offline. Some things may not work.',
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        Expanded(
          // Patti dikhe to neeche wali screens ko status bar ki jagah na do.
          child: MediaQuery.removePadding(
            context: context,
            removeTop: !online,
            child: child,
          ),
        ),
      ],
    );
  }
}
