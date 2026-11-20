import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/models/app_user.dart';
import '../../../data/models/parcel_options.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/job_matching.dart';
import '../../../data/services/location_service.dart';
import '../../auth/auth_providers.dart';
import 'job_providers.dart';

import 'package:go_router/go_router.dart';

class NearbyJobsSection extends ConsumerStatefulWidget {
  const NearbyJobsSection({super.key});

  @override
  ConsumerState<NearbyJobsSection> createState() => _NearbyJobsSectionState();
}

class _NearbyJobsSectionState extends ConsumerState<NearbyJobsSection> {
  static const _staleAfter = Duration(minutes: 15);
  bool _refreshing = false;

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  bool _isStale(AppUser? user) {
    final at = user?.locationAt;
    // Likhne ke dauran server time kuch pal null hota hai: usay taza maano
    if (at == null) return false;
    return DateTime.now().difference(at) > _staleAfter;
  }

  Future<void> _refreshLocation() async {
    if (_refreshing) return;
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) return;
    setState(() => _refreshing = true);
    try {
      final pos = await LocationService.getCurrentPosition();
      await ref
          .read(userRepositoryProvider)
          .setRiderStatus(
            uid,
            online: true,
            lat: pos.latitude,
            lng: pos.longitude,
          )
          .timeout(Duration(seconds: 15));
    } on LocationException catch (e) {
      if (mounted) _snack(e.message);
    } on TimeoutException {
      if (mounted) _snack('Taking too long. Check your internet.');
    } catch (e) {
      debugPrint('Location refresh failed: $e');
      if (mounted) _snack('Could not update your location.');
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appUserProvider).value;
    final jobs = ref.watch(nearbyJobsProvider);
    final stale = _isStale(user);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Nearby parcels',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (jobs.hasValue && jobs.value!.isNotEmpty)
              Container(
                margin: EdgeInsets.only(right: 4),
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0x1F4F7F36),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${jobs.value!.length}',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.green,
                  ),
                ),
              ),
            _refreshing
                ? Padding(
                    padding: EdgeInsets.all(12),
                    child: SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                : IconButton(
                    tooltip: 'Update my location',
                    onPressed: _refreshLocation,
                    icon: Icon(Icons.my_location, color: AppColors.green),
                  ),
          ],
        ),
        SizedBox(height: 4),
        if (stale) ...[
          AppCard(
            child: Row(
              children: [
                Icon(Icons.warning_amber, color: AppColors.danger),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Your location is out of date. Update it to see parcels near you.',
                  ),
                ),
                TextButton(onPressed: _refreshLocation, child: Text('Update')),
              ],
            ),
          ),
          SizedBox(height: 12),
        ],
        jobs.when(
          loading: () => Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => AppCard(
            child: Text('Could not load parcels. Check your internet.'),
          ),
          data: (list) {
            if (list.isEmpty) {
              return AppCard(
                child: Row(
                  children: [
                    Icon(Icons.inbox_outlined, color: context.muted),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'No parcels within ${kJobRadiusKm.round()} km right now. New ones appear here automatically.',
                      ),
                    ),
                  ],
                ),
              );
            }
            return Column(
              children: [
                for (final n in list) ...[
                  _JobCard(
                    nearby: n,
                    onTap: () => context.push('/rider-job-request', extra: n),
                  ),
                  SizedBox(height: 12),
                ],
              ],
            );
          },
        ),
      ],
    );
  }
}

class _JobCard extends StatelessWidget {
  final NearbyJob nearby;
  final VoidCallback onTap;
  const _JobCard({required this.nearby, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final job = nearby.job;
    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _Tag(job.size.label),
                    _Tag('${job.weightKg} kg'),
                    if (job.fragile) const _Tag('Fragile'),
                    if (job.speed == DeliverySpeed.express)
                      const _Tag('Express'),
                  ],
                ),
              ),
              SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'You earn',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  Text(
                    formatRs(job.riderEarning),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.green,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(
                Icons.radio_button_checked,
                size: 16,
                color: AppColors.green,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  job.pickup.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 6),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: AppColors.danger),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  job.drop.address,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            '${nearby.pickupRoadKm.toStringAsFixed(1)} km to pickup  \u2022  ${job.roadKm.toStringAsFixed(1)} km trip',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  final String text;
  const _Tag(this.text);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: context.chip,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: context.ink,
        ),
      ),
    );
  }
}
