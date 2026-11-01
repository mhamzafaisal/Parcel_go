import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../data/services/location_service.dart';

class CurrentLocationScreen extends StatefulWidget {
  const CurrentLocationScreen({super.key});

  @override
  State<CurrentLocationScreen> createState() => _CurrentLocationScreenState();
}

class _CurrentLocationScreenState extends State<CurrentLocationScreen> {
  static const _defaultCenter = LatLng(31.4504, 73.1350);

  final _mapController = MapController();
  bool _mapReady = false;
  LatLng? _position;
  LocationIssue? _issue;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _moveTo(LatLng point) {
    if (!_mapReady) return;
    _mapController.move(point, 16);
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _issue = null;
      _error = null;
    });
    try {
      final pos = await LocationService.getCurrentPosition();
      if (!mounted) return;
      final latLng = LatLng(pos.latitude, pos.longitude);
      setState(() {
        _position = latLng;
        _loading = false;
      });
      _moveTo(latLng);
    } on LocationException catch (e) {
      if (!mounted) return;
      setState(() {
        _issue = e.issue;
        _error = e.message;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not get your location. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  Widget _statusCard() {
    if (_loading) {
      return const AppCard(
        child: Row(
          children: [
            SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2.5)),
            SizedBox(width: 12),
            Text('Finding your location...'),
          ],
        ),
      );
    }

    if (_error != null) {
      return AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_error!, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            Row(
              children: [
                if (_issue == LocationIssue.deniedForever)
                  TextButton(
                    onPressed: LocationService.openAppSettings,
                    child: const Text('Open settings'),
                  ),
                if (_issue == LocationIssue.serviceOff)
                  TextButton(
                    onPressed: LocationService.openLocationSettings,
                    child: const Text('Location settings'),
                  ),
                TextButton(onPressed: _load, child: const Text('Try again')),
              ],
            ),
          ],
        ),
      );
    }

    final p = _position!;
    return AppCard(
      child: Row(
        children: [
          const Icon(Icons.my_location, color: AppColors.green),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'You are here\n${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Map test')),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _position ?? _defaultCenter,
              initialZoom: 14,
              onMapReady: () {
                _mapReady = true;
                final p = _position;
                if (p != null) _moveTo(p);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.hamza.parcelgo.parcel_go',
              ),
              MarkerLayer(
                markers: [
                  if (_position != null)
                    Marker(
                      point: _position!,
                      width: 48,
                      height: 48,
                      alignment: Alignment.topCenter,
                      child: const Icon(Icons.location_on,
                          size: 44, color: AppColors.green),
                    ),
                ],
              ),
              const RichAttributionWidget(
                attributions: [
                  TextSourceAttribution('\u00a9 OpenStreetMap contributors'),
                ],
              ),
            ],
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 40,
            child: _statusCard(),
          ),
          Positioned(
            right: 16,
            bottom: 150,
            child: FloatingActionButton.small(
              backgroundColor: AppColors.white,
              foregroundColor: AppColors.green,
              onPressed: _load,
              child: const Icon(Icons.my_location),
            ),
          ),
        ],
      ),
    );
  }
}