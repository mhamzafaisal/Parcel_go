import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/delivery_steps.dart';
import '../../../data/models/shipment.dart';
import '../../../data/services/pricing_service.dart';
import '../../../data/services/tracking_policy.dart';
import 'tracking_providers.dart';
import '../../../data/repositories/live_location_repository.dart';

class TrackingScreen extends ConsumerStatefulWidget {
  final String shipmentId;
  const TrackingScreen({super.key, required this.shipmentId});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  final _map = MapController();
  bool _mapReady = false;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    // "2 min ago" jaisi likhai taza rakhne ke liye
    _ticker = Timer.periodic(const Duration(seconds: 15), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final shipment = ref.watch(shipmentByIdProvider(widget.shipmentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Track parcel')),
      body: shipment.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            const Center(child: Text('Could not load this shipment.')),
        data: (s) => s == null
            ? const Center(child: Text('Shipment not found.'))
            : _content(s),
      ),
    );
  }

  Widget _content(Shipment s) {
    final pickup = s.pickupPoint;
    final drop = s.dropPoint;
    if (pickup == null || drop == null) {
      return const Center(child: Text('Location details are missing.'));
    }

    const trackingStates = {
      ShipmentStatus.assigned,
      ShipmentStatus.pickedUp,
      ShipmentStatus.inTransit,
    };
    final active = trackingStates.contains(s.status);
    final live = active ? ref.watch(liveLocationProvider(s.id)).value : null;
    final rider = live?.point;
    final now = DateTime.now();

    final toPickup = deliveryTarget(s.status) == DeliveryTarget.pickup;
    final target = toPickup ? pickup : drop;

    double? roadKm;
    int? eta;
    if (rider != null) {
      roadKm = const Distance().as(LengthUnit.Kilometer, rider, target) *
          PricingService.roadFactor;
      eta = etaMinutesFromKm(roadKm);
    }
    final stale =
        live != null && now.difference(live.at) > const Duration(seconds: 90);

    return Column(
      children: [
        // Map
        Expanded(
          flex: 5,
          child: Stack(
            children: [
              FlutterMap(
                mapController: _map,
                options: MapOptions(
                  initialCameraFit: CameraFit.bounds(
                    bounds: LatLngBounds.fromPoints(
                        [pickup, drop, if (rider != null) rider]),
                    padding: const EdgeInsets.all(48),
                  ),
                  onMapReady: () => setState(() => _mapReady = true),
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
                        point: rider,
                        width: 44,
                        height: 44,
                        child: Container(
                          decoration: BoxDecoration(
                            color: stale
                                ? AppColors.textMuted
                                : AppColors.green,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 3),
                          ),
                          child: const Icon(Icons.two_wheeler,
                              color: Colors.white, size: 22),
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
              if (rider != null && _mapReady)
                Positioned(
                  top: 12,
                  right: 12,
                  child: FloatingActionButton.small(
                    heroTag: 'follow_rider',
                    tooltip: 'Follow rider',
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.green,
                    onPressed: () => _map.move(rider, 16),
                    child: const Icon(Icons.two_wheeler),
                  ),
                ),
            ],
          ),
        ),

        // Details
        Expanded(
          flex: 4,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(s.trackingId,
                        style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                            color: AppColors.textDark)),
                  ),
                  StatusChip(status: s.status),
                ],
              ),
              const SizedBox(height: 14),

              _statusCard(
                s: s,
                active: active,
                toPickup: toPickup,
                live: live,
                roadKm: roadKm,
                eta: eta,
                stale: stale,
                now: now,
              ),
              const SizedBox(height: 14),

              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.radio_button_checked,
                            size: 18, color: AppColors.green),
                        const SizedBox(width: 10),
                        Expanded(child: Text(s.pickupAddress)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.location_on,
                            size: 18, color: AppColors.danger),
                        const SizedBox(width: 10),
                        Expanded(child: Text(s.dropAddress)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusCard({
    required Shipment s,
    required bool active,
    required bool toPickup,
    required LiveLocation? live,
    required double? roadKm,
    required int? eta,
    required bool stale,
    required DateTime now,
  }) {
    if (s.status == ShipmentStatus.created) {
      return const AppCard(
        child: Row(
          children: [
            Icon(Icons.search, color: AppColors.green),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                  'Looking for a rider near the pickup location. This usually takes a few minutes.'),
            ),
          ],
        ),
      );
    }
    if (s.status == ShipmentStatus.cancelled) {
      return const AppCard(
        child: Row(
          children: [
            Icon(Icons.cancel_outlined, color: AppColors.danger),
            SizedBox(width: 12),
            Expanded(child: Text('This delivery was cancelled.')),
          ],
        ),
      );
    }
    if (s.status == ShipmentStatus.delivered) {
      return const AppCard(
        child: Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.green),
            SizedBox(width: 12),
            Expanded(child: Text('Your parcel was delivered.')),
          ],
        ),
      );
    }

    // Rider raste mein / pickup ki taraf
    if (live == null || roadKm == null || eta == null) {
      return const AppCard(
        child: Row(
          children: [
            SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5)),
            SizedBox(width: 12),
            Expanded(child: Text("Waiting for the rider's location...")),
          ],
        ),
      );
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            toPickup
                ? 'Rider is heading to the pickup'
                : 'Your parcel is on the way',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            toPickup
                ? 'About ${roadKm.toStringAsFixed(1)} km from pickup  \u2022  arriving in about ${formatEta(eta)}'
                : 'About ${roadKm.toStringAsFixed(1)} km away  \u2022  arriving in about ${formatEta(eta)}',
          ),
          const SizedBox(height: 6),
          Text(
            stale
                ? 'Rider location last updated ${timeAgo(live.at, now)}'
                : 'Updated ${timeAgo(live.at, now)}',
            style: TextStyle(
              fontSize: 12,
              color: stale ? AppColors.danger : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}