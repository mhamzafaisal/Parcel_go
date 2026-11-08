import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/parcel_options.dart';
import '../../../data/repositories/job_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/job_matching.dart';
import '../home/job_providers.dart';

class JobRequestScreen extends ConsumerStatefulWidget {
  final NearbyJob nearby;
  const JobRequestScreen({super.key, required this.nearby});

  @override
  ConsumerState<JobRequestScreen> createState() => _JobRequestScreenState();
}

class _JobRequestScreenState extends ConsumerState<JobRequestScreen> {
  static const _totalSeconds = 30;

  int _secondsLeft = _totalSeconds;
  Timer? _timer;
  bool _accepting = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _accepting) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        _expire();
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _dismissJob() {
    ref.read(dismissedJobsProvider.notifier).dismiss(widget.nearby.job.id);
  }

  void _expire() {
    final messenger = ScaffoldMessenger.of(context);
    _dismissJob();
    context.pop();
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(const SnackBar(content: Text('Request expired')));
  }

  void _reject() {
    _timer?.cancel();
    _dismissJob();
    context.pop();
  }

  Future<void> _accept() async {
    if (_accepting) return;
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) return;

    setState(() => _accepting = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    void say(String text) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));

    try {
      await ref
          .read(jobRepositoryProvider)
          .acceptJob(jobId: widget.nearby.job.id, riderId: uid)
          .timeout(const Duration(seconds: 20));
      _timer?.cancel();
      router.go('/rider-home');
      say('Parcel accepted. Head to the pickup location.');
    } on JobException catch (e) {
      say(e.message);
      if (e.error == JobError.taken || e.error == JobError.gone) {
        _timer?.cancel();
        _dismissJob();
        if (mounted) router.pop();
      } else if (mounted) {
        setState(() => _accepting = false);
      }
    } on TimeoutException {
      say('Taking too long. Check Home to see if it was accepted.');
      if (mounted) setState(() => _accepting = false);
    } catch (e) {
      debugPrint('Accept failed: $e');
      say('Could not accept this parcel. Please try again.');
      if (mounted) setState(() => _accepting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final nearby = widget.nearby;
    final job = nearby.job;
    final pickup = job.pickup.latLng;
    final drop = job.drop.latLng;

    return Scaffold(
      appBar: AppBar(title: const Text('New parcel request')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Chhota map
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                height: 200,
                child: FlutterMap(
                  options: MapOptions(
                    initialCameraFit: CameraFit.bounds(
                      bounds: LatLngBounds.fromPoints([pickup, drop]),
                      padding: const EdgeInsets.all(40),
                    ),
                    interactionOptions:
                        const InteractionOptions(flags: InteractiveFlag.none),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.hamza.parcelgo.parcel_go',
                    ),
                    PolylineLayer(polylines: [
                      Polyline(
                          points: [pickup, drop],
                          strokeWidth: 4,
                          color: AppColors.green),
                    ]),
                    MarkerLayer(markers: [
                      Marker(
                        point: pickup,
                        width: 36,
                        height: 36,
                        child: const Icon(Icons.radio_button_checked,
                            color: AppColors.green, size: 30),
                      ),
                      Marker(
                        point: drop,
                        width: 40,
                        height: 40,
                        alignment: Alignment.topCenter,
                        child: const Icon(Icons.location_on,
                            color: AppColors.danger, size: 38),
                      ),
                    ]),
                    const RichAttributionWidget(
                      attributions: [
                        TextSourceAttribution(
                            '\u00a9 OpenStreetMap contributors'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Kamayi aur countdown
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('You earn',
                            style: Theme.of(context).textTheme.bodyMedium),
                        Text(formatRs(job.riderEarning),
                            style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: AppColors.green)),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 52,
                    width: 52,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          height: 52,
                          width: 52,
                          child: CircularProgressIndicator(
                            value: _secondsLeft / _totalSeconds,
                            strokeWidth: 5,
                            color: _secondsLeft <= 10
                                ? AppColors.danger
                                : AppColors.green,
                            backgroundColor: AppColors.border,
                          ),
                        ),
                        Text('$_secondsLeft',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Details
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _Tag(job.category.label),
                      _Tag(job.size.label),
                      _Tag('${job.weightKg} kg'),
                      if (job.fragile) const _Tag('Fragile'),
                      if (job.speed == DeliverySpeed.express)
                        const _Tag('Express'),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _AddressRow(
                    icon: Icons.radio_button_checked,
                    color: AppColors.green,
                    label: 'Pickup',
                    address: job.pickup.address,
                  ),
                  const SizedBox(height: 12),
                  _AddressRow(
                    icon: Icons.location_on,
                    color: AppColors.danger,
                    label: 'Drop',
                    address: job.drop.address,
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Divider(height: 1, color: AppColors.border),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: _Stat(
                            label: 'To pickup',
                            value:
                                '${nearby.pickupRoadKm.toStringAsFixed(1)} km'),
                      ),
                      Expanded(
                        child: _Stat(
                            label: 'Trip',
                            value: '${job.roadKm.toStringAsFixed(1)} km'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Receiver details are shown after you accept.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 54,
                  child: OutlinedButton(
                    onPressed: _accepting ? null : _reject,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.danger,
                      side: const BorderSide(color: AppColors.danger),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: const Text('Reject',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: PrimaryButton(
                  label: 'Accept parcel',
                  icon: Icons.check,
                  isLoading: _accepting,
                  onPressed: _accept,
                ),
              ),
            ],
          ),
        ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textDark)),
    );
  }
}

class _AddressRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String address;

  const _AddressRow({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodyMedium),
              Text(address,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  final String label;
  final String value;
  const _Stat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}