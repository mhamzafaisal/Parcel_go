import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../utils/errors.dart';
import 'primary_button.dart';

/// Poori screen ka error: icon, saaf paigham aur "Try again".
class ErrorView extends StatelessWidget {
  final Object error;
  final VoidCallback? onRetry;
  final String? title;

  const ErrorView({super.key, required this.error, this.onRetry, this.title});

  @override
  Widget build(BuildContext context) {
    final network = isNetworkError(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              network ? Icons.cloud_off_outlined : Icons.error_outline,
              size: 56,
              color: context.muted,
            ),
            const SizedBox(height: 12),
            Text(
              title ?? (network ? 'You are offline' : 'Something went wrong'),
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              friendlyError(error),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 20),
              SizedBox(
                width: 220,
                child: PrimaryButton(
                  label: 'Try again',
                  icon: Icons.refresh,
                  onPressed: onRetry,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
