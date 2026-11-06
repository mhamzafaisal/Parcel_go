import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../auth/auth_providers.dart';

class RiderProfileScreen extends ConsumerWidget {
  const RiderProfileScreen({super.key});

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final auth = ref.read(authServiceProvider);
    final uid = auth.currentUser?.uid;
    // Pehle offline karo, taake koi purana "online" rider na rahe
    try {
      if (uid != null) {
        await ref
            .read(userRepositoryProvider)
            .setRiderStatus(uid, online: false)
            .timeout(const Duration(seconds: 5));
      }
    } catch (_) {
      // Internet na ho to bhi logout hone do
    }
    await auth.signOut();
    if (context.mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(appUserProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            AppCard(
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0x1F3F5B2E),
                    child: Icon(Icons.two_wheeler, color: AppColors.green),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? '-',
                            style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 2),
                        Text(user?.phone ?? '-',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Sign out',
              icon: Icons.logout,
              onPressed: () => _signOut(context, ref),
            ),
          ],
        ),
      ),
    );
  }
}