import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/widgets/app_card.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/services/auth_service.dart';
import '../auth/auth_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  void _comingSoon(BuildContext context) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Coming soon')));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authServiceProvider).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(child: _ProfileHeader()),
            const SizedBox(height: 24),
            AppCard(
              child: Row(
                children: [
                  const Icon(Icons.phone_outlined, color: AppColors.purple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(user?.phoneNumber ?? 'Not signed in',
                        style: Theme.of(context).textTheme.titleMedium),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _ProfileTile(
              icon: Icons.edit_outlined,
              label: 'Edit profile',
              onTap: () => _comingSoon(context),
            ),
            const SizedBox(height: 12),
            _ProfileTile(
              icon: Icons.help_outline,
              label: 'Help & support',
              onTap: () => _comingSoon(context),
            ),
            const SizedBox(height: 12),
            _ProfileTile(
              icon: Icons.info_outline,
              label: 'About app',
              onTap: () => showAboutDialog(
                context: context,
                applicationName: 'Parcel Go',
                applicationVersion: '1.0.0',
              ),
            ),
            const Spacer(),
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
      ),
    );
  }
}

class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(appUserProvider).value;
    final name = profile?.name ?? '';
    final initial = name.isEmpty ? '?' : name[0].toUpperCase();
    final role = profile?.role.name ?? '';

    return Column(
      children: [
        CircleAvatar(
          radius: 40,
          backgroundColor: AppColors.purple,
          child: Text(
            initial,
            style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: Colors.white),
          ),
        ),
        const SizedBox(height: 12),
        Text(name.isEmpty ? 'Your profile' : name,
            style: Theme.of(context).textTheme.headlineMedium),
        if (role.isNotEmpty) ...[
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.purple.withAlpha(38),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              role.toUpperCase(),
              style: const TextStyle(
                  color: AppColors.purple,
                  fontWeight: FontWeight.w600,
                  fontSize: 12),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProfileTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ProfileTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.purple),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: Theme.of(context).textTheme.titleMedium),
          ),
          const Icon(Icons.chevron_right, color: AppColors.textMuted),
        ],
      ),
    );
  }
}