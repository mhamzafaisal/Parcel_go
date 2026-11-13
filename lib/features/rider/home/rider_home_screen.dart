import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/location_service.dart';
import '../../auth/auth_providers.dart';
import 'rider_providers.dart';
import 'nearby_jobs_section.dart';
import 'active_job_card.dart';
import '../../../data/models/rating.dart';

class RiderHomeScreen extends ConsumerStatefulWidget {
  const RiderHomeScreen({super.key});

  @override
  ConsumerState<RiderHomeScreen> createState() => _RiderHomeScreenState();
}

class _RiderHomeScreenState extends ConsumerState<RiderHomeScreen> {
  bool _busy = false;

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggle(bool goOnline) async {
    if (_busy) return;
    if (!goOnline && ref.read(appUserProvider).value?.activeJobId != null) {
      _snack('Finish your current delivery before going offline.');
      return;
    }
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) return;

    setState(() => _busy = true);
    try {
      final repo = ref.read(userRepositoryProvider);
      if (goOnline) {
        final pos = await LocationService.getCurrentPosition();
        await repo
            .setRiderStatus(uid,
                online: true, lat: pos.latitude, lng: pos.longitude)
            .timeout(const Duration(seconds: 15));
      } else {
        await repo
            .setRiderStatus(uid, online: false)
            .timeout(const Duration(seconds: 15));
      }
    } on LocationException catch (e) {
      if (mounted) _snack(e.message);
    } on TimeoutException {
      if (mounted) _snack('Taking too long. Check your internet.');
    } catch (e) {
      debugPrint('Status change failed: $e');
      if (mounted) _snack('Could not change your status. Please try again.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(appUserProvider).value;
    final online = user?.isOnline ?? false;
    final earnings =
        ref.watch(todayEarningsProvider).value ?? EarningsSummary.zero;
    final firstName = (user?.name ?? '').split(' ').first;
    final stats = ref.watch(riderStatsProvider).value ?? RiderStats.empty;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(_greeting(),
                          style: Theme.of(context).textTheme.bodyMedium),
                      Text(firstName.isEmpty ? 'Rider' : firstName,
                          style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                ),
                _StatusChip(online: online),
              ],
            ),
            const SizedBox(height: 20),

            // Online / offline card
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: online ? AppColors.green : AppColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: online ? AppColors.green : AppColors.border),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (online) ...[
                              const _PulseDot(),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              online ? 'You are online' : 'You are offline',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: online
                                    ? AppColors.cream
                                    : AppColors.textDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          online
                              ? 'Waiting for parcels near you...'
                              : 'Go online to start receiving delivery requests.',
                          style: TextStyle(
                              color: online
                                  ? AppColors.cream
                                  : AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  _OnlineToggle(
                    online: online,
                    busy: _busy,
                    onChanged: _toggle,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (user?.activeJobId != null) ...[
              const ActiveJobCard(),
              const SizedBox(height: 16),
            ] else if (online) ...[
              const NearbyJobsSection(),
              const SizedBox(height: 16),
            ],

            // Today's earnings
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Today's earnings",
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(formatRs(earnings.amount),
                      style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w800,
                          color: AppColors.green)),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: AppColors.border),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                          icon: Icons.inventory_2_outlined,
                          label: 'Deliveries',
                          value: '${earnings.deliveries}',
                        ),
                      ),
                      Expanded(
                        child: _Stat(
                          icon: Icons.star_outline,
                          label: 'Rating',
                          value: ratingLabel(stats)
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            const AppCard(
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: AppColors.textMuted),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                        'Keep the app open while you are online so we can find parcels near you.'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final bool online;
  const _StatusChip({required this.online});

  @override
  Widget build(BuildContext context) {
    final color = online ? AppColors.green : AppColors.textMuted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 6),
          Text(online ? 'Online' : 'Offline',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ],
      ),
    );
  }
}

class _OnlineToggle extends StatelessWidget {
  final bool online;
  final bool busy;
  final ValueChanged<bool> onChanged;

  const _OnlineToggle({
    required this.online,
    required this.busy,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : () => onChanged(!online),
      child: Opacity(
        opacity: busy ? 0.7 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 68,
          height: 38,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: online ? AppColors.cream : AppColors.border,
            borderRadius: BorderRadius.circular(20),
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 250),
            alignment: online ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: online ? AppColors.green : AppColors.textMuted,
                shape: BoxShape.circle,
              ),
              child: busy
                  ? const Padding(
                      padding: EdgeInsets.all(7),
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.white),
                    )
                  : null,
            ),
          ),
        ),
      ),
    );
  }
}

class _PulseDot extends StatefulWidget {
  const _PulseDot();

  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        final t = _c.value;
        return SizedBox(
          width: 24,
          height: 24,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 10 + 14 * t,
                height: 10 + 14 * t,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color.fromRGBO(247, 244, 236, 0.35 * (1 - t)),
                ),
              ),
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.cream),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _Stat({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.green),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
            Text(value, style: Theme.of(context).textTheme.titleMedium),
          ],
        ),
      ],
    );
  }
}