import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/error_view.dart';
import '../../../data/models/earning_entry.dart';
import '../../../data/services/earnings_summary.dart';
import '../../../data/services/pricing_service.dart';
import '../home/rider_providers.dart';

class RiderEarningsScreen extends ConsumerStatefulWidget {
  const RiderEarningsScreen({super.key});

  @override
  ConsumerState<RiderEarningsScreen> createState() =>
      _RiderEarningsScreenState();
}

class _RiderEarningsScreenState extends ConsumerState<RiderEarningsScreen> {
  EarningsPeriod _period = EarningsPeriod.today;

  @override
  Widget build(BuildContext context) {
    final earnings = ref.watch(riderEarningsProvider);

    return Scaffold(
      appBar: AppBar(title: Text('Earnings')),
      body: earnings.when(
        loading: () => Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          error: e,
          onRetry: () => ref.invalidate(riderEarningsProvider),
        ),
        data: _content,
      ),
    );
  }

  Widget _content(List<EarningEntry> all) {
    final now = DateTime.now();
    final sorted = [...all]
      ..sort((a, b) => b.deliveredAt.compareTo(a.deliveredAt));
    final summary = summarizePeriod(sorted, _period, now);
    final inPeriod = entriesInPeriod(sorted, _period, now);
    final week = dailyTotals(sorted, now);
    final sharePercent = (PricingService.riderShare * 100).round();

    return ListView(
      padding: EdgeInsets.all(20),
      children: [
        // Period chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final p in EarningsPeriod.values)
              ChoiceChip(
                label: Text(p.label),
                selected: _period == p,
                showCheckmark: false,
                selectedColor: Color(0x294F7F36),
                onSelected: (_) => setState(() => _period = p),
              ),
          ],
        ),
        SizedBox(height: 16),

        // Summary
        Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.green,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You earned (${_period.label.toLowerCase()})',
                style: TextStyle(color: AppColors.cream),
              ),
              SizedBox(height: 4),
              Text(
                formatRs(summary.earned),
                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.cream,
                ),
              ),
              SizedBox(height: 6),
              Text(
                summary.count == 0
                    ? 'No deliveries'
                    : '${summary.count} deliver${summary.count == 1 ? 'y' : 'ies'}  \u2022  about ${formatRs(summary.average)} each',
                style: TextStyle(color: AppColors.cream),
              ),
            ],
          ),
        ),
        SizedBox(height: 16),

        // Last 7 days
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Last 7 days',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 14),
              _WeekBars(days: week),
            ],
          ),
        ),
        SizedBox(height: 16),

        // Cash summary
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cash summary',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 8),
              _Line('Cash collected', formatRs(summary.cash)),
              _Line('Your share ($sharePercent%)', formatRs(summary.earned)),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: context.line),
              ),
              _Line(
                'Platform share to hand over',
                formatRs(summary.platformFee),
                bold: true,
              ),
              SizedBox(height: 8),
              Text(
                'You collect the full amount in cash from customers and keep your share. The platform share is shown for the deliveries in this period.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
        SizedBox(height: 24),

        // Deliveries
        Text('Deliveries', style: Theme.of(context).textTheme.titleMedium),
        SizedBox(height: 10),
        ..._deliveries(all, inPeriod, now),
      ],
    );
  }

  List<Widget> _deliveries(
    List<EarningEntry> all,
    List<EarningEntry> inPeriod,
    DateTime now,
  ) {
    if (inPeriod.isEmpty) {
      return [
        AppCard(
          child: Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: context.muted),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  all.isEmpty
                      ? 'No deliveries yet. Go online to start earning.'
                      : 'No deliveries in this period.',
                ),
              ),
            ],
          ),
        ),
      ];
    }

    final items = <Widget>[];
    String? lastLabel;
    for (final e in inPeriod) {
      final label = dateGroupLabel(e.deliveredAt, now);
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
      items.add(_DeliveryTile(entry: e));
      items.add(SizedBox(height: 10));
    }
    return items;
  }
}

class _Line extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _Line(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 16 : 14,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      color: bold ? AppColors.green : context.ink,
    );
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text(value, style: style),
        ],
      ),
    );
  }
}

class _DeliveryTile extends StatelessWidget {
  final EarningEntry entry;
  const _DeliveryTile({required this.entry});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        children: [
          Container(
            height: 42,
            width: 42,
            decoration: BoxDecoration(
              color: Color(0x1F4F7F36),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(Icons.check_circle_outline, color: AppColors.green),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.jobId,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                Text(
                  formatDateTime(entry.deliveredAt),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '+${formatRs(entry.amount)}',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.green,
                ),
              ),
              Text(
                'Cash ${formatRs(entry.cash)}',
                style: TextStyle(fontSize: 12, color: context.muted),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Bina kisi package ke saada bar chart
class _WeekBars extends StatelessWidget {
  final List<DayTotal> days;
  const _WeekBars({required this.days});

  @override
  Widget build(BuildContext context) {
    var maxAmount = 0;
    for (final d in days) {
      if (d.amount > maxAmount) maxAmount = d.amount;
    }
    const maxBar = 80.0;

    return SizedBox(
      height: 130,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < days.length; i++)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (days[i].amount > 0)
                    Text(
                      '${days[i].amount}',
                      style: TextStyle(fontSize: 10, color: context.muted),
                    ),
                  SizedBox(height: 4),
                  Container(
                    width: 22,
                    height: maxAmount == 0
                        ? 4
                        : 4 + (days[i].amount / maxAmount) * maxBar,
                    decoration: BoxDecoration(
                      color: i == days.length - 1
                          ? AppColors.green
                          : Color(0x664F7F36),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    DateFormat('E').format(days[i].day),
                    style: TextStyle(fontSize: 11, color: context.muted),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
