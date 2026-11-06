import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:latlong2/latlong.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/place_result.dart';
import '../../../data/services/geocoding_service.dart';
import '../../../data/services/location_service.dart';

class PickerArgs {
  final String title;
  final PlaceResult? initial;
  const PickerArgs({required this.title, this.initial});
}

class LocationPickerScreen extends ConsumerStatefulWidget {
  final PickerArgs args;
  const LocationPickerScreen({super.key, required this.args});

  @override
  ConsumerState<LocationPickerScreen> createState() =>
      _LocationPickerScreenState();
}

class _LocationPickerScreenState extends ConsumerState<LocationPickerScreen> {
  static const _defaultCenter = LatLng(31.4504, 73.1350);

  final _map = MapController();
  final _searchController = TextEditingController();

  bool _mapReady = false;
  bool _pendingMove = false;
  late LatLng _center;
  String? _address;
  bool _resolving = false;
  int _requestId = 0;
  Timer? _debounce;

  List<PlaceResult> _results = [];
  bool _searching = false;
  String? _searchMessage;

  @override
  void initState() {
    super.initState();
    final initial = widget.args.initial;
    _center = initial?.latLng ?? _defaultCenter;
    _address = initial?.address;
    if (initial == null) _useMyLocation(silent: true);
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _useMyLocation({bool silent = false}) async {
    try {
      final pos = await LocationService.getCurrentPosition();
      if (!mounted) return;
      _goTo(LatLng(pos.latitude, pos.longitude));
    } on LocationException catch (e) {
      if (!silent && mounted) _snack(e.message);
    } catch (_) {
      if (!silent && mounted) _snack('Could not get your location.');
    }
  }

  void _goTo(LatLng point, {String? address}) {
    _debounce?.cancel();
    _requestId++;
    setState(() {
      _center = point;
      _address = address;
      _resolving = false;
    });
    if (_mapReady) {
      _map.move(point, 17);
    } else {
      _pendingMove = true;
    }
    if (address == null) _resolve(point);
  }

  void _scheduleResolve() {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 800), () {
      _resolve(_center);
    });
    if (!_resolving) setState(() => _resolving = true);
  }

  Future<void> _resolve(LatLng point) async {
    final id = ++_requestId;
    if (mounted) setState(() => _resolving = true);
    String? result;
    try {
      result = await ref.read(geocodingServiceProvider).reverse(point);
    } catch (_) {
      result = null;
    }
    if (!mounted || id != _requestId) return;
    setState(() {
      _address = result ??
          'Pinned location (${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)})';
      _resolving = false;
    });
  }

  Future<void> _search() async {
    final q = _searchController.text.trim();
    FocusScope.of(context).unfocus();
    if (q.length < 3) {
      setState(() {
        _results = [];
        _searchMessage = 'Type at least 3 letters';
      });
      return;
    }
    setState(() {
      _searching = true;
      _searchMessage = null;
    });
    try {
      final found = await ref.read(geocodingServiceProvider).search(q);
      if (!mounted) return;
      setState(() {
        _results = found;
        _searchMessage = found.isEmpty
            ? 'No places found. Try a nearby landmark or area name.'
            : null;
      });
    } on GeocodingException catch (e) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _searchMessage = e.message;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _results = [];
        _searchMessage = 'Search failed. Please try again.';
      });
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  void _selectResult(PlaceResult p) {
    setState(() => _results = []);
    _goTo(p.latLng, address: p.address);
  }

  void _confirm() {
    final address = _address;
    if (address == null || _resolving) {
      _snack('Please wait, finding the address...');
      return;
    }
    context.pop(PlaceResult(
      address: address,
      latitude: _center.latitude,
      longitude: _center.longitude,
    ));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    _map.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final addressText = _resolving
        ? 'Finding address...'
        : (_address ?? 'Move the map to choose a place');

    return Scaffold(
      appBar: AppBar(title: Text(widget.args.title)),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _map,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: 16,
              onMapReady: () {
                _mapReady = true;
                if (_pendingMove) {
                  _pendingMove = false;
                  _map.move(_center, 17);
                }
              },
              onPositionChanged: (camera, hasGesture) {
                _center = camera.center;
                if (hasGesture) _scheduleResolve();
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hamza.parcelgo.parcel_go',
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('\u00a9 OpenStreetMap contributors'),
                ],
              ),
            ],
          ),

          // Beech wala pin (nok bilkul center par)
          const IgnorePointer(
            child: Center(
              child: Padding(
                padding: EdgeInsets.only(bottom: 44),
                child: Icon(Icons.location_on,
                    size: 44, color: AppColors.green),
              ),
            ),
          ),

          // Search
          Positioned(
            top: 12,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                          color: AppColors.shadow,
                          blurRadius: 12,
                          offset: Offset(0, 4)),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _search(),
                    decoration: InputDecoration(
                      hintText: 'Search area or landmark',
                      prefixIcon: const Icon(Icons.search,
                          color: AppColors.textMuted),
                      suffixIcon: _searching
                          ? const Padding(
                              padding: EdgeInsets.all(14),
                              child: SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2.5)),
                            )
                          : IconButton(
                              onPressed: _search,
                              icon: const Icon(Icons.arrow_forward,
                                  color: AppColors.green),
                            ),
                    ),
                  ),
                ),
                if (_searchMessage != null) ...[
                  const SizedBox(height: 8),
                  AppCard(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline,
                            color: AppColors.textMuted),
                        const SizedBox(width: 10),
                        Expanded(child: Text(_searchMessage!)),
                      ],
                    ),
                  ),
                ],
                if (_results.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    constraints: const BoxConstraints(maxHeight: 240),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 12,
                            offset: Offset(0, 4)),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _results.length,
                        separatorBuilder: (_, _) =>
                            const Divider(height: 1, color: AppColors.border),
                        itemBuilder: (context, i) {
                          final p = _results[i];
                          return ListTile(
                            leading: const Icon(Icons.place_outlined,
                                color: AppColors.green),
                            title: Text(p.address,
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                            onTap: () => _selectResult(p),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Neeche: my-location button aur address card
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: FloatingActionButton.small(
                      heroTag: 'picker_my_location',
                      backgroundColor: AppColors.white,
                      foregroundColor: AppColors.green,
                      onPressed: () => _useMyLocation(),
                      child: const Icon(Icons.my_location),
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.location_on,
                                color: AppColors.green),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                addressText,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style:
                                    Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        PrimaryButton(
                            label: 'Confirm location', onPressed: _confirm),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}