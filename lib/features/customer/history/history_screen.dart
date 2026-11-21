import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/error_view.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/shipment_card.dart';
import '../../../data/models/shipment.dart';
import '../../../data/services/shipment_filter.dart';
import '../create_shipment/shipment_draft.dart';
import '../home/home_providers.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _search = TextEditingController();
  HistoryFilter _filter = HistoryFilter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _startNewShipment() {
    ref.read(shipmentDraftProvider.notifier).reset();
    context.push('/create-shipment');
  }

  @override
  Widget build(BuildContext context) {
    final shipments = ref.watch(myShipmentsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('My orders')),
      body: shipments.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(myShipmentsProvider),
        ),
        data: _content,
      ),
    );
  }

  Widget _content(List<Shipment> all) {
    final query = _search.text;
    final filtered = filterShipments(all, _filter, query);
    final now = DateTime.now();

    return Column(
      children: [
        // Search
        Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Search by tracking ID, name or address',
              prefixIcon: Icon(Icons.search, color: context.muted),
              suffixIcon: query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear',
                      onPressed: () {
                        _search.clear();
                        setState(() {});
                      },
                      icon: Icon(Icons.close, color: context.muted),
                    ),
            ),
          ),
        ),

        // Filters
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 20),
            children: [
              for (final f in HistoryFilter.values) ...[
                ChoiceChip(
                  label: Text(
                    '${f.label} (${all.where((s) => matchesFilter(s, f)).length})',
                  ),
                  selected: _filter == f,
                  showCheckmark: false,
                  selectedColor: Color(0x294F7F36),
                  onSelected: (_) => setState(() => _filter = f),
                ),
                SizedBox(width: 8),
              ],
            ],
          ),
        ),
        SizedBox(height: 8),

        // List
        Expanded(child: _list(all, filtered, query, now)),
      ],
    );
  }

  Widget _list(
    List<Shipment> all,
    List<Shipment> filtered,
    String query,
    DateTime now,
  ) {
    if (all.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.inventory_2_outlined, size: 56, color: context.muted),
              SizedBox(height: 12),
              Text(
                'No shipments yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 4),
              Text(
                'Your parcels will appear here.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 20),
              PrimaryButton(
                label: 'Send a parcel',
                icon: Icons.send_outlined,
                onPressed: _startNewShipment,
              ),
            ],
          ),
        ),
      );
    }

    if (filtered.isEmpty) {
      final searching = query.trim().isNotEmpty;
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            searching
                ? 'No shipments match your search.'
                : 'No ${_filter.label.toLowerCase()} shipments.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      );
    }

    final items = <Widget>[];
    String? lastLabel;
    for (final s in filtered) {
      final label = dateGroupLabel(s.createdAt, now);
      if (label != lastLabel) {
        items.add(
          Padding(
            padding: EdgeInsets.only(
              top: lastLabel == null ? 0 : 8,
              bottom: 10,
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.muted,
              ),
            ),
          ),
        );
        lastLabel = label;
      }
      items.add(ShipmentCard(shipment: s));
      items.add(SizedBox(height: 12));
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
      children: items,
    );
  }
}
