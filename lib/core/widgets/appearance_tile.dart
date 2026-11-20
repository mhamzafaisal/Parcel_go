import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../app/theme_mode_provider.dart';
import '../../data/services/theme_storage.dart';
import 'app_card.dart';

/// Profile mein "Appearance": System default, Light ya Dark chunne ka tile
class AppearanceTile extends ConsumerWidget {
  const AppearanceTile({super.key});

  IconData _icon(ThemeMode m) {
    switch (m) {
      case ThemeMode.light:
        return Icons.light_mode_outlined;
      case ThemeMode.dark:
        return Icons.dark_mode_outlined;
      case ThemeMode.system:
        return Icons.brightness_auto_outlined;
    }
  }

  void _choose(BuildContext context, WidgetRef ref, ThemeMode current) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: context.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(height: 8),
            for (final m in ThemeMode.values)
              ListTile(
                leading: Icon(_icon(m), color: AppColors.green),
                title: Text(themeModeLabel(m)),
                trailing: m == current
                    ? Icon(Icons.check, color: AppColors.green)
                    : null,
                onTap: () {
                  ref.read(themeModeProvider.notifier).set(m);
                  Navigator.pop(sheetContext);
                },
              ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(themeModeProvider);
    return AppCard(
      onTap: () => _choose(context, ref, mode),
      child: Row(
        children: [
          Icon(_icon(mode), color: AppColors.green),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          Text(
            themeModeLabel(mode),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          SizedBox(width: 6),
          Icon(Icons.chevron_right, color: context.muted),
        ],
      ),
    );
  }
}
