import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../app/theme.dart';
import '../../../core/utils/phone.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/parcel_options.dart';
import 'shipment_draft.dart';

class ParcelDetailsScreen extends ConsumerStatefulWidget {
  const ParcelDetailsScreen({super.key});

  @override
  ConsumerState<ParcelDetailsScreen> createState() =>
      _ParcelDetailsScreenState();
}

class _ParcelDetailsScreenState extends ConsumerState<ParcelDetailsScreen> {
  static const _maxPhotoBytes = 300 * 1024;

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _weight;
  late final TextEditingController _receiverName;
  late final TextEditingController _receiverPhone;
  late final TextEditingController _notes;

  late ParcelCategory _category;
  late ParcelSize _size;
  late bool _fragile;
  Uint8List? _photo;

  @override
  void initState() {
    super.initState();
    final d = ref.read(shipmentDraftProvider);
    _category = d.category;
    _size = d.size;
    _fragile = d.fragile;
    _photo = d.photo;
    _weight = TextEditingController(
        text: d.weightKg == null ? '' : d.weightKg.toString());
    _receiverName = TextEditingController(text: d.receiverName);
    _receiverPhone = TextEditingController(text: d.receiverPhone);
    _notes = TextEditingController(text: d.notes);
  }

  @override
  void dispose() {
    _weight.dispose();
    _receiverName.dispose();
    _receiverPhone.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String? _validateWeight(String? v) {
    final w = double.tryParse((v ?? '').trim().replaceAll(',', '.'));
    if (w == null) return 'Enter weight in kg, e.g. 1.5';
    if (w < 0.1 || w > 25) return 'Weight must be between 0.1 and 25 kg';
    return null;
  }

  String? _validateName(String? v) {
    if (v == null || v.trim().length < 2) return 'Enter receiver name';
    return null;
  }

  String? _validatePhone(String? v) {
    if (normalizePkPhone(v ?? '') == null) {
      return 'Enter a valid mobile number, e.g. 03001234567';
    }
    return null;
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 720,
        maxHeight: 720,
        imageQuality: 55,
      );
      if (file == null) return;
      final bytes = await file.readAsBytes();
      if (!mounted) return;
      if (bytes.length > _maxPhotoBytes) {
        _snack('Photo is too large. Please choose a smaller photo.');
        return;
      }
      setState(() => _photo = bytes);
    } catch (_) {
      if (mounted) _snack('Could not open the camera or gallery.');
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined,
                  color: AppColors.green),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: AppColors.green),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickPhoto(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) {
      _snack('Please fix the highlighted fields');
      return;
    }
    final weight =
        double.parse(_weight.text.trim().replaceAll(',', '.'));
    ref.read(shipmentDraftProvider.notifier).setParcel(
          category: _category,
          size: _size,
          weightKg: weight,
          fragile: _fragile,
          receiverName: _receiverName.text.trim(),
          receiverPhone: normalizePkPhone(_receiverPhone.text)!,
          notes: _notes.text.trim(),
          photo: _photo,
        );
    context.push('/shipment-summary');
        
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(shipmentDraftProvider);

    // Page refresh ke baad draft khali ho jata hai
    if (!draft.hasLocations) {
      return Scaffold(
        appBar: AppBar(title: const Text('Parcel details')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Please choose pickup and drop locations first.'),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: 'Choose locations',
                  onPressed: () => context.go('/create-shipment'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Parcel details')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Route summary
              AppCard(
                onTap: () => context.pop(),
                child: Row(
                  children: [
                    Column(
                      children: const [
                        Icon(Icons.radio_button_checked,
                            size: 18, color: AppColors.green),
                        SizedBox(height: 6),
                        Icon(Icons.location_on,
                            size: 18, color: AppColors.danger),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(draft.pickup!.address,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 8),
                          Text(draft.drop!.address,
                              maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const Text('Edit',
                        style: TextStyle(
                            color: AppColors.green,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Category
              Text('What are you sending?',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final c in ParcelCategory.values)
                    ChoiceChip(
                      label: Text(c.label),
                      selected: _category == c,
                      showCheckmark: false,
                      selectedColor: const Color(0x293F5B2E),
                      onSelected: (_) => setState(() => _category = c),
                    ),
                ],
              ),
              const SizedBox(height: 24),

              // Size
              Text('Parcel size',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final s in ParcelSize.values) ...[
                    Expanded(
                      child: _SizeCard(
                        size: s,
                        selected: _size == s,
                        onTap: () => setState(() => _size = s),
                      ),
                    ),
                    if (s != ParcelSize.values.last) const SizedBox(width: 10),
                  ],
                ],
              ),
              const SizedBox(height: 20),

              AppTextField(
                label: 'Weight',
                hint: 'e.g. 1.5',
                icon: Icons.scale_outlined,
                suffixText: 'kg',
                controller: _weight,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                validator: _validateWeight,
              ),
              const SizedBox(height: 16),

              // Fragile
              AppCard(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeThumbColor: AppColors.green,
                  title: Text('Fragile item',
                      style: Theme.of(context).textTheme.titleMedium),
                  subtitle: const Text('Rider will handle it with extra care'),
                  value: _fragile,
                  onChanged: (v) => setState(() => _fragile = v),
                ),
              ),
              const SizedBox(height: 24),

              // Photo
              Text('Parcel photo (optional)',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              if (_photo == null)
                AppCard(
                  onTap: _showPhotoOptions,
                  child: const Row(
                    children: [
                      Icon(Icons.add_a_photo_outlined,
                          color: AppColors.green),
                      SizedBox(width: 12),
                      Expanded(
                          child: Text('Add a photo to help the rider identify it')),
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
                        tooltip: 'Change',
                        onPressed: _showPhotoOptions,
                        icon: const Icon(Icons.edit_outlined,
                            color: AppColors.green),
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

              // Receiver
              Text('Receiver details',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 10),
              AppTextField(
                label: 'Receiver name',
                hint: 'e.g. Ahmed Raza',
                icon: Icons.person_outline,
                controller: _receiverName,
                textCapitalization: TextCapitalization.words,
                validator: _validateName,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Receiver mobile number',
                hint: '03001234567',
                icon: Icons.phone_outlined,
                controller: _receiverPhone,
                keyboardType: TextInputType.phone,
                validator: _validatePhone,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Note for rider (optional)',
                hint: 'e.g. Call on arrival, 2nd floor',
                icon: Icons.sticky_note_2_outlined,
                controller: _notes,
                maxLines: 2,
                maxLength: 150,
              ),
              const SizedBox(height: 24),
              PrimaryButton(label: 'Continue', onPressed: _continue),
            ],
          ),
        ),
      ),
    );
  }
}

class _SizeCard extends StatelessWidget {
  final ParcelSize size;
  final bool selected;
  final VoidCallback onTap;

  const _SizeCard({
    required this.size,
    required this.selected,
    required this.onTap,
  });

  IconData get _icon {
    switch (size) {
      case ParcelSize.small:
        return Icons.mail_outline;
      case ParcelSize.medium:
        return Icons.inventory_2_outlined;
      case ParcelSize.large:
        return Icons.all_inbox_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0x143F5B2E) : AppColors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.green : AppColors.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(_icon, size: 28, color: AppColors.green),
            const SizedBox(height: 8),
            Text(size.label,
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark)),
            const SizedBox(height: 2),
            Text(size.hint,
                textAlign: TextAlign.center,
                maxLines: 2,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}