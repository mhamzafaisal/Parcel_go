import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/models/place_result.dart';
import '../../data/models/saved_address.dart';
import '../../data/repositories/address_repository.dart';
import '../../data/repositories/user_repository.dart';
import '../../data/services/auth_service.dart';
import '../auth/auth_providers.dart';
import '../customer/create_shipment/location_picker_screen.dart';
import 'address_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  IconData _iconFor(String label) {
    final l = label.toLowerCase();
    if (l.contains('home') || l.contains('ghar')) return Icons.home_outlined;
    if (l.contains('office') || l.contains('work')) return Icons.work_outline;
    return Icons.place_outlined;
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final name = await showDialog<String>(
      context: context,
      builder: (_) => _NameDialog(initial: current),
    );
    if (name == null || name == current) return;
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) return;
    try {
      await ref
          .read(userRepositoryProvider)
          .updateName(uid, name)
          .timeout(const Duration(seconds: 15));
      if (context.mounted) _snack(context, 'Name updated');
    } catch (e) {
      debugPrint('Name update failed: $e');
      if (context.mounted) _snack(context, 'Could not update your name.');
    }
  }

  Future<void> _addAddress(BuildContext context, WidgetRef ref) async {
    final count = ref.read(savedAddressesProvider).value?.length ?? 0;
    if (count >= kMaxSavedAddresses) {
      _snack(
        context,
        'You can save up to $kMaxSavedAddresses addresses. Delete one first.',
      );
      return;
    }
    final place = await context.push<PlaceResult>(
      '/pick-location',
      extra: const PickerArgs(title: 'Choose address to save'),
    );
    if (place == null || !context.mounted) return;

    final label = await showDialog<String>(
      context: context,
      builder: (_) => const _LabelDialog(),
    );
    if (label == null) return;
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) return;
    try {
      await ref
          .read(addressRepositoryProvider)
          .add(uid, label: label, place: place)
          .timeout(const Duration(seconds: 15));
      if (context.mounted) _snack(context, 'Address saved');
    } catch (e) {
      debugPrint('Address save failed: $e');
      if (context.mounted) _snack(context, 'Could not save the address.');
    }
  }

  Future<void> _deleteAddress(
    BuildContext context,
    WidgetRef ref,
    SavedAddress a,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete "${a.label}"?'),
        content: const Text('This address will be removed from your list.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.danger),
            ),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) return;
    try {
      await ref.read(addressRepositoryProvider).delete(uid, a.id);
    } catch (e) {
      debugPrint('Address delete failed: $e');
      if (context.mounted) _snack(context, 'Could not delete the address.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).value;
    final addresses = ref.watch(savedAddressesProvider);
    final name = user?.name ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Profile card
          AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.green,
                  child: Text(
                    initialsOf(name),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.cream,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name.isEmpty ? '-' : name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user?.phone ?? '-',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Edit name',
                  onPressed: name.isEmpty
                      ? null
                      : () => _editName(context, ref, name),
                  icon: const Icon(Icons.edit_outlined, color: AppColors.green),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Saved addresses
          Row(
            children: [
              Expanded(
                child: Text(
                  'Saved addresses',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              TextButton.icon(
                onPressed: () => _addAddress(context, ref),
                icon: const Icon(Icons.add, size: 18, color: AppColors.green),
                label: const Text(
                  'Add',
                  style: TextStyle(color: AppColors.green),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          addresses.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) =>
                const AppCard(child: Text('Could not load your addresses.')),
            data: (list) {
              if (list.isEmpty) {
                return const AppCard(
                  child: Row(
                    children: [
                      Icon(Icons.bookmark_border, color: AppColors.textMuted),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Save places like Home or Office to pick them quickly when booking.',
                        ),
                      ),
                    ],
                  ),
                );
              }
              return Column(
                children: [
                  for (final a in list) ...[
                    AppCard(
                      child: Row(
                        children: [
                          Icon(_iconFor(a.label), color: AppColors.green),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.label,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium,
                                ),
                                Text(
                                  a.place.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Delete',
                            onPressed: () => _deleteAddress(context, ref, a),
                            icon: const Icon(
                              Icons.delete_outline,
                              color: AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Settings
          Text('Settings', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.notifications_none,
            title: 'Notifications',
            onTap: () => context.push('/notifications'),
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.language,
            title: 'Language',
            subtitle: 'English',
            onTap: () => _snack(context, 'Language options come in Task 28'),
          ),
          const SizedBox(height: 10),
          _SettingsTile(
            icon: Icons.dark_mode_outlined,
            title: 'Dark mode',
            subtitle: 'Off',
            onTap: () => _snack(context, 'Dark mode comes in Task 28'),
          ),
          const SizedBox(height: 10),
          const _SettingsTile(
            icon: Icons.info_outline,
            title: 'About ParcelGo',
            subtitle: 'Version 1.0.0',
          ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Sign out',
            icon: Icons.logout,
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.green),
          const SizedBox(width: 14),
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleMedium),
          ),
          if (subtitle != null)
            Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
          if (onTap != null) ...[
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
          ],
        ],
      ),
    );
  }
}

class _NameDialog extends StatefulWidget {
  final String initial;
  const _NameDialog({required this.initial});

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.initial,
  );
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final error = validatePersonName(_controller.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit name'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        maxLength: 40,
        textCapitalization: TextCapitalization.words,
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(errorText: _error),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}

class _LabelDialog extends StatefulWidget {
  const _LabelDialog();

  @override
  State<_LabelDialog> createState() => _LabelDialogState();
}

class _LabelDialogState extends State<_LabelDialog> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _save() {
    final error = validateAddressLabel(_controller.text);
    if (error != null) {
      setState(() => _error = error);
      return;
    }
    Navigator.pop(context, _controller.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Name this address'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            children: [
              for (final l in const ['Home', 'Office', 'Other'])
                ActionChip(
                  label: Text(l),
                  onPressed: () => setState(() {
                    _controller.text = l;
                    _error = null;
                  }),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            maxLength: 20,
            textCapitalization: TextCapitalization.words,
            onSubmitted: (_) => _save(),
            decoration: InputDecoration(
              hintText: 'e.g. Home',
              errorText: _error,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(onPressed: _save, child: const Text('Save')),
      ],
    );
  }
}
