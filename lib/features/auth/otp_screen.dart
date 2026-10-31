import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/services/auth_service.dart';
import '../../data/repositories/user_repository.dart';

class OtpArgs {
  final String phone;
  final ConfirmationResult confirmation;
  const OtpArgs({required this.phone, required this.confirmation});
}

class OtpScreen extends ConsumerStatefulWidget {
  final OtpArgs args;
  const OtpScreen({super.key, required this.args});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _codeController = TextEditingController();
  late ConfirmationResult _confirmation;
  Timer? _timer;
  int _secondsLeft = 30;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _confirmation = widget.args.confirmation;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsLeft <= 1) {
        t.cancel();
        setState(() => _secondsLeft = 0);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

    Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _snack('Enter the 6-digit code');
      return;
    }
    setState(() => _loading = true);
    try {
      final cred =
          await ref.read(authServiceProvider).verifyOtp(_confirmation, code);
      final profile =
          await ref.read(userRepositoryProvider).getUser(cred.user!.uid);
      if (!mounted) return;
      context.go(UserRepository.homeRouteFor(profile));
    } catch (e) {
      if (!mounted) return;
      _snack(AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      final result =
          await ref.read(authServiceProvider).sendOtp(widget.args.phone);
      if (!mounted) return;
      _confirmation = result;
      setState(() => _secondsLeft = 30);
      _startTimer();
      _snack('A new code was sent');
    } catch (e) {
      if (!mounted) return;
      _snack(AuthService.friendlyError(e));
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verify your number',
                  style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 8),
              Text('Enter the 6-digit code sent to ${widget.args.phone}',
                  style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 32),
              TextField(
                controller: _codeController,
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
              const SizedBox(height: 24),
              PrimaryButton(
                label: 'Verify',
                isLoading: _loading,
                onPressed: _verify,
              ),
              const SizedBox(height: 16),
              Center(
                child: _secondsLeft > 0
                    ? Text('Resend code in $_secondsLeft s',
                        style: Theme.of(context).textTheme.bodyMedium)
                    : TextButton(
                        onPressed: _resend,
                        child: const Text('Resend code',
                            style: TextStyle(color: AppColors.green)),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}