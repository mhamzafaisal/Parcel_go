import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/star_row.dart';
import '../../../data/models/rating.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../auth/auth_providers.dart';
import '../home/rider_providers.dart';

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
    final stats = ref.watch(riderStatsProvider).value ?? RiderStats.empty;
    final reviews = ref.watch(riderReviewsProvider).value ?? const <Rating>[];
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
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
          const SizedBox(height: 16),

          // Rating
          AppCard(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Your rating',
                          style: Theme.of(context).textTheme.bodyMedium),
                      const SizedBox(height: 4),
                      Text(ratingLabel(stats),
                          style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.green)),
                    ],
                  ),
                ),
                if (stats.average != null)
                  StarRow(stars: stats.average!.round(), size: 26),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Reviews
          Text('Recent reviews',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (reviews.isEmpty)
            const AppCard(
              child: Row(
                children: [
                  Icon(Icons.rate_review_outlined,
                      color: AppColors.textMuted),
                  SizedBox(width: 12),
                  Expanded(child: Text('No reviews yet.')),
                ],
              ),
            )
          else
            for (final r in reviews.take(10)) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        StarRow(stars: r.stars),
                        const Spacer(),
                        Text(timeAgo(r.createdAt, now),
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(r.comment.isEmpty ? 'No comment' : r.comment,
                        style: r.comment.isEmpty
                            ? const TextStyle(color: AppColors.textMuted)
                            : null),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],
          const SizedBox(height: 14),
          PrimaryButton(
            label: 'Sign out',
            icon: Icons.logout,
            onPressed: () => _signOut(context, ref),
          ),
        ],
      ),
    );
  }
}