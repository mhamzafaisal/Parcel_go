import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app/theme.dart';
import '../../core/widgets/primary_button.dart';
import '../../data/services/onboarding_storage.dart';

class _Slide {
  final IconData icon;
  final String title;
  final String text;
  const _Slide(this.icon, this.title, this.text);
}

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;

  static const _slides = [
    _Slide(Icons.inventory_2_outlined, 'Send parcels easily',
        'Enter pickup and drop address, choose size and book in a minute.'),
    _Slide(Icons.location_on_outlined, 'Track in real time',
        'See your rider on the map and know exactly when it arrives.'),
    _Slide(Icons.verified_outlined, 'Safe and secure delivery',
        'Delivery OTP and photo proof make sure your parcel reaches the right person.'),
  ];

  bool get _isLast => _index == _slides.length - 1;

  Future<void> _finish() async {
    await OnboardingStorage.setSeen();
    if (!mounted) return;
    context.go('/login');
  }

  void _next() {
    if (_isLast) {
      _finish();
    } else {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _finish,
                  child: const Text('Skip',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, i) {
                    final s = _slides[i];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          height: 170,
                          width: 170,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0x1F3F5B2E),
                          ),
                          child: Icon(s.icon,
                              size: 80, color: AppColors.green),
                        ),
                        const SizedBox(height: 36),
                        Text(s.title,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium),
                        const SizedBox(height: 12),
                        Text(s.text,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_slides.length, (i) {
                  final active = i == _index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 8,
                    width: active ? 24 : 8,
                    decoration: BoxDecoration(
                      color: active ? AppColors.green : AppColors.border,
                      borderRadius: BorderRadius.circular(8),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              PrimaryButton(
                label: _isLast ? 'Get started' : 'Next',
                onPressed: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}