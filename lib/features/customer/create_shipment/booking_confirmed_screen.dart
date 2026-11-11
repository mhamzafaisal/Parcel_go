import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/parcel_options.dart';

class BookingConfirmation {
  final String shipmentId;
  final String trackingId;
  final String otp;
  final int total;
  final int etaMinutes;
  final PaymentPayer payer;

  const BookingConfirmation({
    required this.shipmentId,
    required this.trackingId,
    required this.otp,
    required this.total,
    required this.etaMinutes,
    required this.payer,
  });
}

class BookingConfirmedScreen extends StatelessWidget {
  final BookingConfirmation data;
  const BookingConfirmedScreen({super.key, required this.data});

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _copy(BuildContext context, String text, String what) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (context.mounted) _snack(context, '$what copied');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 16),
            Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 700),
                curve: Curves.elasticOut,
                builder: (context, value, child) =>
                    Transform.scale(scale: value, child: child),
                child: Container(
                  height: 96,
                  width: 96,
                  decoration: const BoxDecoration(
                      color: AppColors.green, shape: BoxShape.circle),
                  child: const Icon(Icons.check,
                      size: 56, color: AppColors.cream),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: Text('Booking confirmed!',
                  style: Theme.of(context).textTheme.headlineMedium),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text('A rider will be assigned to your parcel soon.',
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            const SizedBox(height: 24),

            // Tracking ID
            AppCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Tracking ID',
                            style: Theme.of(context).textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Text(data.trackingId,
                            style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2,
                                color: AppColors.textDark)),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Copy',
                    onPressed: () =>
                        _copy(context, data.trackingId, 'Tracking ID'),
                    icon: const Icon(Icons.copy_outlined,
                        color: AppColors.green),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // OTP
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
                                style: Theme.of(context).textTheme.bodyMedium),
                            const SizedBox(height: 4),
                            Text(data.otp,
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
                        onPressed: () =>
                            _copy(context, data.otp, 'Delivery code'),
                        icon: const Icon(Icons.copy_outlined,
                            color: AppColors.green),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Give this code to the receiver. The rider will ask for it when handing over the parcel. Do not share it with anyone else.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Details
            AppCard(
              child: Column(
                children: [
                  _DetailRow('Amount', formatRs(data.total)),
                  _DetailRow('Payment', 'Cash'),
                  _DetailRow('Who pays', data.payer.label),
                  _DetailRow(
                      'Estimated time', 'About ${formatEta(data.etaMinutes)}'),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryButton(
              label: 'Track parcel',
              icon: Icons.location_searching,
              onPressed: () => context.push('/track/${data.shipmentId}'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 54,
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => context.go('/home'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.green,
                  side: const BorderSide(color: AppColors.green),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                child: const Text('Back to home',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
              child:
                  Text(label, style: Theme.of(context).textTheme.bodyMedium)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    );
  }
}