import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart' hide StepState;
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/delivery_steps.dart';
import '../../../data/models/parcel_options.dart';
import '../../../data/models/shipment.dart';
import '../../../data/models/shipment_event.dart';
import '../../../data/models/shipment_timeline.dart';
import '../../../data/repositories/live_location_repository.dart';
import '../../../data/services/pricing_service.dart';
import '../../../data/services/tracking_policy.dart';
import 'tracking_providers.dart';
import 'rating_card.dart';
import 'rating_providers.dart';

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

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copy(String text, String what) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _snack('$what copied');
  }

  void _showPhoto(Uint8List bytes) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: const EdgeInsets.all(12),
        child: Stack(
          children: [
            InteractiveViewer(
              child: Image.memory(bytes, fit: BoxFit.contain),
            ),
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget RatingCard({required String shipmentId, required dynamic rating}) {
    return AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.star_outline, color: AppColors.green),
        title: const Text('Rate your delivery'),
        subtitle: Text('Shipment $shipmentId'),
      ),
    );
  }

  String _kg(double v) => v == v.roundToDouble() ? '${v.round()} kg' : '$v kg';

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
    final finished = s.status == ShipmentStatus.delivered ||
        s.status == ShipmentStatus.cancelled;
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

    // Tafseel
    final events = ref.watch(shipmentEventsProvider(s.id)).value ??
        const <ShipmentEvent>[];
    final timeline = buildTimeline(s.status, events);
    final code = finished ? null : ref.watch(deliveryCodeProvider(s.id)).value;
    final parcelPhoto = s.hasPhoto
        ? ref.watch(shipmentPhotoProvider((s.id, 'main')))
        : null;
    final proofPhoto = s.status == ShipmentStatus.delivered
        ? ref.watch(shipmentPhotoProvider((s.id, 'proof')))
        : null;
    final deliveredAt = timeline.last.at;

    return Column(
      children: [
        // Map (upar fixed)
        SizedBox(
          height: 260,
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

        // Tafseel (scroll hoti hai)
        Expanded(
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
                toPickup: toPickup,
                live: live,
                roadKm: roadKm,
                eta: eta,
                stale: stale,
                now: now,
              ),
              const SizedBox(height: 14),
              if (s.status == ShipmentStatus.delivered && s.riderId != null) ...[
                RatingCard(
                  shipmentId: s.id,
                  rating: ref.watch(ratingProvider(s.id)),
                ),
                const SizedBox(height: 14),
              ],

              // Addresses
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
              const SizedBox(height: 14),

              // Delivery code
              if (code != null) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Delivery code',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium),
                                const SizedBox(height: 4),
                                Text(code,
                                    style: const TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 6,
                                        color: AppColors.green)),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Copy',
                            onPressed: () => _copy(code, 'Delivery code'),
                            icon: const Icon(Icons.copy_outlined,
                                color: AppColors.green),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Give this code to the receiver. The rider needs it to complete the delivery. Do not share it with anyone else.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Timeline
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Timeline',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 14),
                    for (var i = 0; i < timeline.length; i++)
                      _TimelineTile(
                        entry: timeline[i],
                        isLast: i == timeline.length - 1,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Parcel
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Parcel',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _Tag(s.category.label),
                        _Tag(s.size.label),
                        if (s.weightKg > 0) _Tag(_kg(s.weightKg)),
                        if (s.fragile) const _Tag('Fragile'),
                        _Tag(s.speed.label),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 18, color: AppColors.textMuted),
                        const SizedBox(width: 10),
                        Expanded(child: Text(s.receiverName)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.phone_outlined,
                            size: 18, color: AppColors.textMuted),
                        const SizedBox(width: 10),
                        Expanded(child: Text(s.receiverPhone)),
                      ],
                    ),
                    if (s.notes.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.sticky_note_2_outlined,
                              size: 18, color: AppColors.textMuted),
                          const SizedBox(width: 10),
                          Expanded(child: Text(s.notes)),
                        ],
                      ),
                    ],
                    if (parcelPhoto != null) ...[
                      const SizedBox(height: 14),
                      _PhotoView(
                        photo: parcelPhoto,
                        emptyText: 'Photo not available.',
                        onOpen: _showPhoto,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Price
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Price details',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 8),
                    for (final l in s.priceLines)
                      _KeyValueRow(l.label, formatRs(l.amount)),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Divider(height: 1, color: AppColors.border),
                    ),
                    _KeyValueRow('Total', formatRs(s.price.round()),
                        bold: true),
                    const SizedBox(height: 6),
                    Text(
                      s.payer == null
                          ? 'Cash'
                          : 'Cash  \u2022  ${s.payer!.label}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),

              // Proof of delivery
              if (proofPhoto != null) ...[
                const SizedBox(height: 14),
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Proof of delivery',
                          style: Theme.of(context).textTheme.titleMedium),
                      if (deliveredAt != null) ...[
                        const SizedBox(height: 2),
                        Text('Delivered ${formatDateTime(deliveredAt)}',
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                      const SizedBox(height: 10),
                      _PhotoView(
                        photo: proofPhoto,
                        emptyText: 'No proof photo was added.',
                        onOpen: _showPhoto,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }

  Widget _statusCard({
    required Shipment s,
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

class _KeyValueRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _KeyValueRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 17 : 14,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: bold ? AppColors.green : AppColors.textDark,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _PhotoView extends StatelessWidget {
  final AsyncValue<Uint8List?> photo;
  final String emptyText;
  final void Function(Uint8List) onOpen;

  const _PhotoView({
    required this.photo,
    required this.emptyText,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    return photo.when(
      loading: () => const SizedBox(
        height: 60,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2.5)),
      ),
      error: (e, _) => const Text('Could not load the photo.'),
      data: (bytes) => bytes == null
          ? Text(emptyText)
          : GestureDetector(
              onTap: () => onOpen(bytes),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.memory(
                  bytes,
                  height: 160,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final TimelineEntry entry;
  final bool isLast;
  const _TimelineTile({required this.entry, required this.isLast});

  @override
  Widget build(BuildContext context) {
    final done = entry.state == StepState.done;
    final current = entry.state == StepState.current;
    final color = done || current ? AppColors.green : AppColors.border;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                color: done ? AppColors.green : AppColors.white,
                shape: BoxShape.circle,
                border: Border.all(color: color, width: 2),
              ),
              child: done
                  ? const Icon(Icons.check, size: 15, color: AppColors.white)
                  : current
                      ? const Center(
                          child: Icon(Icons.circle,
                              size: 9, color: AppColors.green))
                      : null,
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 32,
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
                  entry.title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                    color: entry.state == StepState.upcoming
                        ? AppColors.textMuted
                        : AppColors.textDark,
                  ),
                ),
                if (done && entry.at != null)
                  Text(formatDateTime(entry.at!),
                      style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ),
      ],
    );
  }
}