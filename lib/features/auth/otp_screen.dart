import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/services/auth_service.dart';

class OtpArgs {
  final String phone;
  final OtpSession session;
  const OtpArgs({required this.phone, required this.session});
}

class OtpScreen extends ConsumerStatefulWidget {
  final OtpArgs args;
  const OtpScreen({super.key, required this.args});

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _codeController = TextEditingController();
  late OtpSession _session;
  Timer? _timer;
  int _secondsLeft = 30;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _session = widget.args.session;
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 1), (t) {
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
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();
    if (code.length != 6) {
      _snack('Enter the 6-digit code');
      return;
    }
    setState(() => _loading = true);
    try {
      await _session.confirm(code).timeout(const Duration(seconds: 30));
      // Aage ka (Home ya Role select) router khud tay karta hai.
    } catch (e) {
      if (!mounted) return;
      _snack(AuthService.friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    try {
      final session = await ref
          .read(authServiceProvider)
          .sendOtp(widget.args.phone, resendToken: _session.resendToken);
      if (!mounted) return;
      _session = session;
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
          padding: EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Verify your number',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              SizedBox(height: 8),
              Text(
                'Enter the 6-digit code sent to ${widget.args.phone}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              SizedBox(height: 32),
              TextField(
                controller: _codeController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 10,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                ),
              ),
              SizedBox(height: 24),
              PrimaryButton(
                label: 'Verify',
                isLoading: _loading,
                onPressed: _verify,
              ),
              SizedBox(height: 16),
              Center(
                child: _secondsLeft > 0
                    ? Text(
                        'Resend code in $_secondsLeft s',
                        style: Theme.of(context).textTheme.bodyMedium,
                      )
                    : TextButton(
                        onPressed: _resend,
                        child: Text(
                          'Resend code',
                          style: TextStyle(color: AppColors.green),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
