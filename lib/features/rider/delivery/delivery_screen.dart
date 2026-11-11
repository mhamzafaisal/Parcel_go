import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide StepState;
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/launcher.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/delivery_steps.dart';
import '../../../data/models/parcel_options.dart';
import '../../../data/models/shipment.dart';
import '../../../data/repositories/user_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/pricing_service.dart';
import '../../auth/auth_providers.dart';
import '../home/job_providers.dart';
import '../../../data/repositories/shipment_repository.dart';
import '../../../data/repositories/live_location_repository.dart';

class DeliveryScreen extends ConsumerStatefulWidget {
  const DeliveryScreen({super.key});

  @override
  ConsumerState<DeliveryScreen> createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends ConsumerState<DeliveryScreen> {
  bool _updatingLocation = false;
  bool _advancing = false;

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _updateLocation() async {
    if (_updatingLocation) return;
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) return;
    setState(() => _updatingLocation = true);
    try {
      final pos = await LocationService.getCurrentPosition();
      await ref
          .read(userRepositoryProvider)
          .setRiderStatus(uid,
              online: true, lat: pos.latitude, lng: pos.longitude)
          .timeout(const Duration(seconds: 15));

      final shipmentId = ref.read(activeShipmentProvider).value?.id;
      if (shipmentId != null) {
        await ref
            .read(liveLocationRepositoryProvider)
            .publish(shipmentId, lat: pos.latitude, lng: pos.longitude);
      }
    } on LocationException catch (e) {
      if (mounted) _snack(e.message);
    } on TimeoutException {
      if (mounted) _snack('Taking too long. Check your internet.');
    } catch (e) {
      debugPrint('Location update failed: $e');
      if (mounted) _snack('Could not update your location.');
    } finally {
      if (mounted) setState(() => _updatingLocation = false);
    }
  }

  Future<void> _advance(Shipment s, LatLng? riderPoint) async {
    if (_advancing) return;
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) return;

    if (s.status == ShipmentStatus.inTransit) {
      context.push('/rider-handover');
      return;
    }
    final next = nextRiderStatus(s.status);
    if (next == null) return;

    String title;
    String message;
    if (next == ShipmentStatus.pickedUp) {
      title = 'Picked up the parcel?';
      message = 'Confirm only after you have collected the parcel from the sender.';
      final pickup = s.pickupPoint;
      if (riderPoint != null && pickup != null) {
        final km =
            const Distance().as(LengthUnit.Kilometer, riderPoint, pickup);
        if (km > 0.5) {
          message =
              'Your last known location is ${km.toStringAsFixed(1)} km from the pickup point. $message';
        }
      }
    } else {
      title = 'Start the trip?';
      message = 'The customer will see that the parcel is on the way.';
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Not yet'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;

    setState(() => _advancing = true);
    try {
      await ref
          .read(shipmentRepositoryProvider)
          .advanceStatus(shipmentId: s.id, riderId: uid, to: next)
          .timeout(const Duration(seconds: 15));
    } on TimeoutException {
      if (mounted) _snack('Taking too long. Check your internet.');
    } catch (e) {
      debugPrint('Status update failed: $e');
      if (mounted) _snack('Could not update the status. Please try again.');
    } finally {
      if (mounted) setState(() => _advancing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shipment = ref.watch(activeShipmentProvider);
    final riderPoint = ref.watch(appUserProvider.select((a) => a.value?.location));

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery')),
      body: shipment.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            const Center(child: Text('Could not load your delivery.')),
        data: (s) {
          if (s == null) return _NoDelivery(onBack: () => context.go('/rider-home'));
          final pickup = s.pickupPoint;
          final drop = s.dropPoint;
          if (pickup == null || drop == null) {
            return const Center(child: Text('Location details are missing.'));
          }
          return _Body(
            shipment: s,
            pickup: pickup,
            drop: drop,
            rider: riderPoint,
            updatingLocation: _updatingLocation,
            onUpdateLocation: _updateLocation,
            onAction: () => _advance(s, riderPoint),
            actionBusy: _advancing,
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  final Shipment shipment;
  final LatLng pickup;
  final LatLng drop;
  final LatLng? rider;
  final bool updatingLocation;
  final VoidCallback onUpdateLocation;
  final VoidCallback onAction;
  final bool actionBusy;

  const _Body({
    required this.shipment,
    required this.pickup,
    required this.drop,
    required this.rider,
    required this.updatingLocation,
    required this.onUpdateLocation,
    required this.onAction,
    required this.actionBusy,
  });

  @override
  Widget build(BuildContext context) {
    final s = shipment;
    final target = deliveryTarget(s.status);
    final toPickup = target == DeliveryTarget.pickup;
    final targetPoint = toPickup ? pickup : drop;
    final targetAddress = toPickup ? s.pickupAddress : s.dropAddress;
    final steps = buildDeliverySteps(s.status);
    final actionLabel = nextActionLabel(s.status);

    double? kmAway;
    if (rider != null) {
      kmAway = const Distance().as(LengthUnit.Kilometer, rider!, targetPoint) *
          PricingService.roadFactor;
    }

    final cashLabel = s.payer == null
        ? null
        : s.payer == PaymentPayer.sender
            ? 'Collect ${formatRs(s.price.round())} from the sender at pickup'
            : 'Collect ${formatRs(s.price.round())} from the receiver on delivery';

    return Column(
      children: [
        // Map
        SizedBox(
          height: 270,
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(
                        [pickup, drop, if (rider != null) rider!]),
                    padding: const EdgeInsets.all(48),
                  ),
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
                    if (rider != null)
                      Marker(
                        point: rider!,
                        width: 24,
                        height: 24,
                        child: Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFF2F6FDE),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                        ),
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
              Positioned(
                top: 12,
                right: 12,
                child: FloatingActionButton.small(
                  heroTag: 'delivery_my_location',
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.green,
                  onPressed: updatingLocation ? null : onUpdateLocation,
                  child: updatingLocation
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.5))
                      : const Icon(Icons.my_location),
                ),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.circle, size: 10, color: AppColors.green),
                      SizedBox(width: 6),
                      Text('Sharing live location',
                          style: TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),

        // Details
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              if (s.status == ShipmentStatus.cancelled) ...[
                const AppCard(
                  child: Row(
                    children: [
                      Icon(Icons.cancel_outlined, color: AppColors.danger),
                      SizedBox(width: 12),
                      Expanded(child: Text('This delivery was cancelled.')),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Next stop
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            toPickup ? 'Go to pickup' : 'Go to drop',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        StatusChip(status: s.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(targetAddress,
                        maxLines: 3, overflow: TextOverflow.ellipsis),
                    if (kmAway != null) ...[
                      const SizedBox(height: 6),
                      Text('About ${kmAway.toStringAsFixed(1)} km away',
                          style: Theme.of(context).textTheme.bodyMedium),
                    ],
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: 'Navigate',
                      icon: Icons.directions_outlined,
                      onPressed: () => openDirections(context, targetPoint),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Steps
              AppCard(
                child: Column(
                  children: [
                    for (var i = 0; i < steps.length; i++)
                      _StepTile(step: steps[i], isLast: i == steps.length - 1),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Cash
              if (cashLabel != null) ...[
                AppCard(
                  child: Row(
                    children: [
                      const Icon(Icons.payments_outlined,
                          color: AppColors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(cashLabel,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Receiver
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Receiver',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(s.receiverName,
                                  style:
                                      Theme.of(context).textTheme.titleMedium),
                              Text(s.receiverPhone),
                            ],
                          ),
                        ),
                        IconButton.filledTonal(
                          tooltip: 'Call receiver',
                          onPressed: () =>
                              callNumber(context, s.receiverPhone),
                          icon: const Icon(Icons.call_outlined),
                        ),
                      ],
                    ),
                    if (s.notes.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.sticky_note_2_outlined,
                              size: 18, color: AppColors.textMuted),
                          const SizedBox(width: 8),
                          Expanded(child: Text(s.notes)),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              if (actionLabel != null) ...[
                const SizedBox(height: 20),
                PrimaryButton(
                  label: actionLabel,
                  isLoading: actionBusy,
                  onPressed: onAction,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StepTile extends StatelessWidget {
  final DeliveryStep step;
  final bool isLast;
  const _StepTile({required this.step, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final done = step.state == StepState.done;
    final current = step.state == StepState.current;
    final color = done || current ? AppColors.green : AppColors.border;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              height: 26,
              width: 26,
              decoration: BoxDecoration(
                color: done ? AppColors.green : AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: done
                  ? const Icon(Icons.check, size: 16, color: AppColors.white)
                  : current
                      ? const Center(
                          child: Icon(Icons.circle,
                              size: 10, color: AppColors.green))
                      : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 34,
                color: done ? AppColors.green : AppColors.border,
              ),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                    color: step.state == StepState.upcoming
                        ? AppColors.textMuted
                        : AppColors.textDark,
                  ),
                ),
                if (current) ...[
                  const SizedBox(height: 2),
                  Text(step.instruction,
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NoDelivery extends StatelessWidget {
  final VoidCallback onBack;
  const _NoDelivery({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You have no active delivery.'),
            const SizedBox(height: 16),
            PrimaryButton(label: 'Back to home', onPressed: onBack),
          ],
        ),
      ),
    );
  }
}