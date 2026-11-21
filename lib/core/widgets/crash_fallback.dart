import 'package:flutter/material.dart';

/// Release mein widget toot jane par laal screen ki jagah ye dikhta hai.
class CrashFallback extends StatelessWidget {
  const CrashFallback({super.key});

  @override
  Widget build(BuildContext context) {
    return const Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(
        color: Color(0xFF111611),
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Something went wrong. Please go back and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFFEDF1E6),
                fontSize: 14,
                decoration: TextDecoration.none,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
