import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/theme.dart';
import '../../../core/utils/format.dart';
import '../../../core/utils/launcher.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/parcel_options.dart';
import '../../../data/models/shipment.dart';
import '../../../data/repositories/shipment_repository.dart';
import '../../../data/services/auth_service.dart';
import '../home/job_providers.dart';

class HandoverScreen extends ConsumerStatefulWidget {
  const HandoverScreen({super.key});

  @override
  ConsumerState<HandoverScreen> createState() => _HandoverScreenState();
}

class _HandoverScreenState extends ConsumerState<HandoverScreen> {
  static const _maxPhotoBytes = 300 * 1024;
  static const _maxWrongAttempts = 5;
  static const _lockSeconds = 30;

  final _code = TextEditingController();
  Uint8List? _photo;
  bool _cashCollected = false;
  bool _submitting = false;
  int _wrongAttempts = 0;
  DateTime? _lockedUntil;

  @override
  void dispose() {
    _code.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _takePhoto() async {
    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.camera,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 55,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > _maxPhotoBytes) {
        _snack('Photo is too large. Please take another one.');
        return;
      }
      setState(() => _photo = bytes);
    } catch (_) {
      if (mounted) _snack('Could not open the camera.');
    }
  }

  Future<void> _submit(Shipment s) async {
    if (_submitting) return;

    final until = _lockedUntil;
    if (until != null && DateTime.now().isBefore(until)) {
      final left = until.difference(DateTime.now()).inSeconds + 1;
      _snack('Too many wrong attempts. Try again in $left seconds.');
      return;
    }

    final code = _code.text.trim();
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      _snack('Enter the 6-digit delivery code');
      return;
    }
    if (s.payer == PaymentPayer.receiver && !_cashCollected) {
      _snack('Please confirm that you collected the cash');
      return;
    }
    final uid = ref.read(authServiceProvider).currentUser?.uid;
    if (uid == null) return;

    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    void say(String text) => messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));

    try {
      final earning = await ref
          .read(shipmentRepositoryProvider)
          .completeDelivery(
            shipmentId: s.id,
            riderId: uid,
            code: code,
            proofPhoto: _photo,
          )
          .timeout(const Duration(seconds: 20));
      router.go('/rider-home');
      say('Delivery complete! You earned ${formatRs(earning)}.');
    } on TimeoutException {
      say('Taking too long. Check Home to see if the delivery went through.');
    } on FirebaseException catch (e) {
      debugPrint('Delivery failed: ${e.code}');
      if (e.code == 'permission-denied') {
        _wrongAttempts++;
        if (_wrongAttempts >= _maxWrongAttempts) {
          _wrongAttempts = 0;
          _lockedUntil =
              DateTime.now().add(const Duration(seconds: _lockSeconds));
          say('Too many wrong attempts. Try again in $_lockSeconds seconds.');
        } else {
          say('That code does not match. Please check it with the receiver.');
        }
      } else {
        say('Could not complete the delivery. Please try again.');
      }
    } catch (e) {
      debugPrint('Delivery failed: $e');
      say('Could not complete the delivery. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final shipment = ref.watch(activeShipmentProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Hand over parcel')),
      body: shipment.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) =>
            const Center(child: Text('Could not load your delivery.')),
        data: (s) {
          if (s == null || s.status != ShipmentStatus.inTransit) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Nothing to hand over right now.'),
                    const SizedBox(height: 16),
                    PrimaryButton(
                      label: 'Back to home',
                      onPressed: () => context.go('/rider-home'),
                    ),
                  ],
                ),
              ),
            );
          }
          return _form(s);
        },
      ),
    );
  }

  Widget _form(Shipment s) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Receiver
          AppCard(
            child: Row(
              children: [
                const Icon(Icons.person_outline, color: AppColors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(s.receiverName,
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(s.receiverPhone),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Call receiver',
                  onPressed: () => callNumber(context, s.receiverPhone),
                  icon: const Icon(Icons.call_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Code
          Text('Delivery code',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            'Ask the receiver for the 6-digit code from the booking confirmation.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _code,
            keyboardType: TextInputType.number,
            textAlign: TextAlign.center,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: 10),
            decoration: const InputDecoration(
              counterText: '',
              hintText: '------',
            ),
          ),
          const SizedBox(height: 20),

          // Cash
          if (s.payer == PaymentPayer.receiver) ...[
            AppCard(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: AppColors.green,
                value: _cashCollected,
                onChanged: (v) => setState(() => _cashCollected = v ?? false),
                title: Text(
                    'I collected ${formatRs(s.price.round())} in cash from the receiver'),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Photo
          Text('Proof photo (optional)',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          if (_photo == null)
            AppCard(
              onTap: _takePhoto,
              child: const Row(
                children: [
                  Icon(Icons.photo_camera_outlined, color: AppColors.green),
                  SizedBox(width: 12),
                  Expanded(child: Text('Take a photo of the delivered parcel')),
                ],
              ),
            )
          else
            AppCard(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.memory(_photo!,
                        height: 84, width: 84, fit: BoxFit.cover),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                        'Photo added (${(_photo!.length / 1024).round()} KB)'),
                  ),
                  IconButton(
                    tooltip: 'Retake',
                    onPressed: _takePhoto,
                    icon: const Icon(Icons.refresh, color: AppColors.green),
                  ),
                  IconButton(
                    tooltip: 'Remove',
                    onPressed: () => setState(() => _photo = null),
                    icon: const Icon(Icons.delete_outline,
                        color: AppColors.danger),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 24),
          PrimaryButton(
            label: 'Confirm delivery',
            icon: Icons.check_circle_outline,
            isLoading: _submitting,
            onPressed: () => _submit(s),
          ),
        ],
      ),
    );
  }
}