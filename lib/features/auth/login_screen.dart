import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/services/auth_service.dart';
import 'otp_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  bool _loading = false;

  String _digits(String? value) {
    var digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('0')) digits = digits.substring(1);
    return digits;
  }

  String? _validate(String? value) {
    final digits = _digits(value);
    if (digits.length != 10 || !digits.startsWith('3')) {
      return 'Enter a valid mobile number, e.g. 3001234567';
    }
    return null;
  }

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    final phone = '+92${_digits(_phoneController.text)}';
    try {
      final result = await ref.read(authServiceProvider).sendOtp(phone);
      if (!mounted) return;
      context.push('/otp', extra: OtpArgs(phone: phone, confirmation: result));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AuthService.friendlyError(e))));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Container(
                  height: 64,
                  width: 64,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(Icons.local_shipping_rounded,
                      color: AppColors.cream, size: 34),
                ),
                const SizedBox(height: 28),
                Text('Welcome to ParcelGo',
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 8),
                Text('Enter your mobile number. We will send you a 6-digit code.',
                    style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 32),
                AppTextField(
                  label: 'Mobile number (+92)',
                  hint: '3001234567',
                  icon: Icons.phone_outlined,
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: _validate,
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: 'Send code',
                  isLoading: _loading,
                  onPressed: _sendCode,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}