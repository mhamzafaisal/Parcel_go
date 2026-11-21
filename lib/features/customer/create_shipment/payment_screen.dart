import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/theme.dart';
import '../../../core/utils/errors.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/parcel_options.dart';
import '../../../data/repositories/shipment_repository.dart';
import '../../../data/services/auth_service.dart';
import '../../../data/services/pricing_service.dart';
import 'booking_confirmed_screen.dart';
import 'shipment_draft.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  const PaymentScreen({super.key});

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  PaymentPayer _payer = PaymentPayer.sender;
  bool _booking = false;
  bool _done = false;

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _confirm(ShipmentDraft draft, PriceBreakdown price) async {
    if (_booking) return;
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) return;

    if (!PricingService.isInRange(draft.straightKm ?? 0)) {
      _snack('These locations are too far for city delivery.');
      return;
    }

    setState(() => _booking = true);
    try {
      final result = await ref
          .read(shipmentRepositoryProvider)
          .createShipment(
            uid: uid,
            pickup: draft.pickup!,
            drop: draft.drop!,
            category: draft.category,
            size: draft.size,
            weightKg: draft.weightKg!,
            fragile: draft.fragile,
            speed: draft.speed,
            receiverName: draft.receiverName,
            receiverPhone: draft.receiverPhone,
            notes: draft.notes,
            photo: draft.photo,
            price: price,
            payer: _payer,
          );
      if (!mounted) return;

      final confirmation = BookingConfirmation(
        shipmentId: result.trackingId,
        trackingId: result.trackingId,
        otp: result.otp,
        total: price.total,
        etaMinutes: price.etaMinutes,
        payer: _payer,
      );

      // Draft saaf karo taake peeche (back) se dobara booking na ho sake
      setState(() => _done = true);
      ref.read(shipmentDraftProvider.notifier).reset();
      context.go('/booking-confirmed', extra: confirmation);
    } on TimeoutException {
      if (!mounted) return;
      _snack(
        'Taking too long. Check your internet. Your booking may still go through, so check Home before trying again.',
      );
    } catch (e) {
      debugPrint('Booking failed: $e');
      if (!mounted) return;
      _snack(actionError(e, 'Could not save your booking. Please try again.'));
    } finally {
      if (mounted && !_done) setState(() => _booking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_done) {
      return Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final draft = ref.watch(shipmentDraftProvider);
    final price = draft.quote;

    // Page refresh ke baad draft khali ho jata hai
    if (price == null) {
      return Scaffold(
        appBar: AppBar(title: Text('Payment')),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Please fill in your shipment details first.'),
                SizedBox(height: 16),
                PrimaryButton(
                  label: 'Start again',
                  onPressed: () => context.go('/create-shipment'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('Payment')),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // Total
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
                    'Total to pay',
                    style: TextStyle(color: AppColors.cream),
                  ),
                  SizedBox(height: 4),
                  Text(
                    formatRs(price.total),
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.cream,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '${draft.speed.label} delivery  \u2022  about ${formatEta(price.etaMinutes)}',
                    style: TextStyle(color: AppColors.cream),
                  ),
                ],
              ),
            ),
            SizedBox(height: 24),

            Text(
              'Payment method',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 10),
            const _MethodTile(
              icon: Icons.payments_outlined,
              title: 'Cash',
              subtitle: 'Pay the rider in cash',
              selected: true,
            ),
            SizedBox(height: 10),
            const _MethodTile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'JazzCash / Easypaisa',
              subtitle: 'Mobile wallet',
              comingSoon: true,
            ),
            SizedBox(height: 10),
            const _MethodTile(
              icon: Icons.credit_card,
              title: 'Debit / Credit card',
              subtitle: 'Visa, Mastercard',
              comingSoon: true,
            ),
            SizedBox(height: 24),

            Text(
              'Who will pay the rider?',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            SizedBox(height: 10),
            for (final p in PaymentPayer.values) ...[
              _MethodTile(
                icon: p == PaymentPayer.sender
                    ? Icons.north_east
                    : Icons.south_west,
                title: p.label,
                selected: _payer == p,
                onTap: () => setState(() => _payer = p),
              ),
              SizedBox(height: 10),
            ],
            SizedBox(height: 6),
            Text(
              'By confirming, you agree that the parcel does not contain any illegal or dangerous items.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            SizedBox(height: 20),
            PrimaryButton(
              label: 'Confirm booking',
              icon: Icons.check_circle_outline,
              isLoading: _booking,
              onPressed: () => _confirm(draft, price),
            ),
          ],
        ),
      ),
    );
  }
}

class _MethodTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final bool comingSoon;
  final VoidCallback? onTap;

  const _MethodTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.selected = false,
    this.comingSoon = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tile = InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: comingSoon ? null : onTap,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 200),
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? Color(0x144F7F36) : context.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.green : context.line,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.green),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
            if (comingSoon)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: context.chip,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Coming soon',
                  style: TextStyle(fontSize: 11, color: context.muted),
                ),
              )
            else
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? AppColors.green : context.line,
              ),
          ],
        ),
      ),
    );
    return comingSoon ? Opacity(opacity: 0.55, child: tile) : tile;
  }
}
