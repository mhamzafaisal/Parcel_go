import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/shipment_card.dart';
import '../../../data/repositories/shipment_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../auth/auth_providers.dart';
import 'home_providers.dart';
import '../create_shipment/shipment_draft.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _trackController = TextEditingController();
  bool _tracking = false;

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

  void _openCreateShipment() {
    ref.read(shipmentDraftProvider.notifier).reset();
    context.push('/create-shipment');
  }

  Future<void> _track() async {
    final id = _trackController.text.trim().toUpperCase();
    if (id.isEmpty) {
      _snack('Enter a tracking ID');
      return;
    }
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) return;

    setState(() => _tracking = true);
    try {
      final s = await ref.read(shipmentRepositoryProvider).findByTrackingId(uid, id);
      if (!mounted) return;
      if (s == null) {
        _snack('No shipment found with this ID');
      } else {
        context.push('/track/${s.id}');
      }
    } catch (_) {
      if (!mounted) return;
      _snack('Could not search. Check your internet.');
    } finally {
      if (mounted) setState(() => _tracking = false);
    }
  }

  @override
  void dispose() {
    _trackController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = ref.watch(appUserProvider).value?.name ?? '';
    final firstName = name.split(' ').first;
    final shipments = ref.watch(myShipmentsProvider);

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
                      Text(firstName.isEmpty ? 'Welcome' : firstName,
                          style: Theme.of(context).textTheme.headlineMedium),
                    ],
                  ),
                ),
                Container(
                  decoration: const BoxDecoration(
                      color: AppColors.white, shape: BoxShape.circle),
                  child: IconButton(
                    onPressed: () =>
                        _snack('Notifications come in Task 25'),
                    icon: const Icon(Icons.notifications_none,
                        color: AppColors.textDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Send card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.green,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.local_shipping_rounded,
                      color: AppColors.cream, size: 34),
                  const SizedBox(height: 12),
                  const Text('Send a parcel',
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cream)),
                  const SizedBox(height: 4),
                  const Text('Fast pickup and safe delivery across the city.',
                      style: TextStyle(color: AppColors.cream)),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton.icon(
                      onPressed: _openCreateShipment,
                      icon: const Icon(Icons.send_outlined, size: 18),
                      label: const Text('Send now'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.cream,
                        foregroundColor: AppColors.green,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Track box
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Track your parcel',
                      style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _trackController,
                    textCapitalization: TextCapitalization.characters,
                    textInputAction: TextInputAction.search,
                    onSubmitted: (_) => _track(),
                    decoration: const InputDecoration(
                      hintText: 'Enter tracking ID, e.g. PG1024',
                      prefixIcon: Icon(Icons.search, color: AppColors.textMuted),
                    ),
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                      label: 'Track', isLoading: _tracking, onPressed: _track),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Recent shipments
            Row(
              children: [
                Expanded(
                  child: Text('Recent shipments',
                      style: Theme.of(context).textTheme.titleMedium),
                ),
                TextButton(
                  onPressed: () => context.go('/history'),
                  child: const Text('See all',
                      style: TextStyle(color: AppColors.green)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            shipments.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => const AppCard(
                child: Text('Could not load shipments. Check your internet.'),
              ),
              data: (list) {
                if (list.isEmpty) {
                  return const AppCard(
                    child: Row(
                      children: [
                        Icon(Icons.inventory_2_outlined,
                            color: AppColors.textMuted),
                        SizedBox(width: 12),
                        Expanded(
                            child: Text(
                                'No shipments yet. Your parcels will appear here.')),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    for (final s in list.take(5)) ...[
                      ShipmentCard(shipment: s),
                      const SizedBox(height: 12),
                    ],
                  ],
                );
              },
            ),

            if (kDebugMode) ...[
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () => context.push('/map-test'),
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Map test (debug)'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}