import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../data/services/onboarding_storage.dart';
import 'auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _loadSession() async {
    final user = await ref.read(authStateProvider.future);
    if (user != null) {
      await ref.read(appUserProvider.future);
    }
  }

  Future<void> _start() async {
    if (_failed) setState(() => _failed = false);
    try {
      await Future.wait([
        Future.delayed(const Duration(seconds: 2)),
        _loadSession(),
      ]);
      final seen = await OnboardingStorage.isSeen();
      if (!mounted) return;
      // Asli manzil router khud tay karega (login, role select, customer ya rider)
      context.go(seen ? '/home' : '/onboarding');
    } catch (_) {
      if (mounted) setState(() => _failed = true);
    }
  }

  void _retry() {
    ref.invalidate(authStateProvider);
    ref.invalidate(appUserProvider);
    _start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.green,
      body: Center(
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.8, end: 1.0),
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeOutBack,
          builder: (context, value, child) => Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Transform.scale(scale: value, child: child),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_shipping_rounded,
                  size: 84, color: AppColors.cream),
              const SizedBox(height: 16),
              const Text('ParcelGo',
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      color: AppColors.cream)),
              const SizedBox(height: 8),
              const Text('Send. Track. Delivered.',
                  style: TextStyle(fontSize: 15, color: AppColors.cream)),
              if (_failed) ...[
                const SizedBox(height: 28),
                const Text('Could not load. Check your internet.',
                    style: TextStyle(color: AppColors.cream)),
                const SizedBox(height: 12),
                OutlinedButton(
                  onPressed: _retry,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.cream,
                    side: const BorderSide(color: AppColors.cream),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}