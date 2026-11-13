import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../app/theme.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/star_row.dart';
import '../../../data/models/rating.dart';
import '../../../data/models/shipment.dart';
import '../../../data/repositories/rating_repository.dart';
import '../../../data/services/auth_service.dart';
import 'rating_providers.dart';
import 'tracking_providers.dart';

class RatingScreen extends ConsumerStatefulWidget {
  final String shipmentId;
  const RatingScreen({super.key, required this.shipmentId});

  @override
  ConsumerState<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends ConsumerState<RatingScreen> {
  final _comment = TextEditingController();
  int _stars = 0;
  bool _submitting = false;

  @override
  void dispose() {
    _comment.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit(Shipment s) async {
    if (_submitting) return;
    if (_stars == 0) {
      _snack('Please choose a star rating');
      return;
    }
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    final riderId = s.riderId;
    if (uid == null || riderId == null) return;

    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    try {
      await ref
          .read(ratingRepositoryProvider)
          .submitRating(
            shipmentId: s.id,
            riderId: riderId,
            customerId: uid,
            stars: _stars,
            comment: _comment.text.trim(),
          )
          .timeout(const Duration(seconds: 15));
      router.pop();
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
            const SnackBar(content: Text('Thanks for your feedback!')));
    } catch (e) {
      debugPrint('Rating failed: $e');
      if (mounted) {
        _snack('Could not submit your rating. Please try again.');
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shipment = ref.watch(shipmentByIdProvider(widget.shipmentId));
    final existing = ref.watch(ratingProvider(widget.shipmentId));

    return Scaffold(
      appBar: AppBar(title: const Text('Rate your rider')),
      body: shipment.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            const Center(child: Text('Could not load this shipment.')),
        data: (s) {
          if (s == null) return const Center(child: Text('Shipment not found.'));
          if (s.status != ShipmentStatus.delivered || s.riderId == null) {
            return const _Message('You can rate a delivery after it is delivered.');
          }
          return existing.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) =>
                const Center(child: Text('Could not load your rating.')),
            data: (r) => r != null
                ? const _Message('You already rated this delivery.')
                : _form(s),
          );
        },
      ),
    );
  }

  Widget _form(Shipment s) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('How was your delivery?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 6),
          Text(s.trackingId,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 28),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 1; i <= 5; i++)
                IconButton(
                  tooltip: '$i star${i == 1 ? '' : 's'}',
                  onPressed: _submitting ? null : () => setState(() => _stars = i),
                  iconSize: 44,
                  icon: Icon(
                    i <= _stars
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: kStarColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _stars == 0 ? 'Tap a star' : starLabel(_stars),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _stars == 0 ? AppColors.textMuted : AppColors.textDark,
            ),
          ),
          const SizedBox(height: 28),
          AppTextField(
            label: 'Comment (optional)',
            hint: 'Tell us more about the delivery',
            icon: Icons.chat_bubble_outline,
            controller: _comment,
            maxLines: 3,
            maxLength: 200,
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Submit',
            isLoading: _submitting,
            onPressed: () => _submit(s),
          ),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final String text;
  const _Message(this.text);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}