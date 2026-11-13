import 'package:flutter/material.dart';

const kStarColor = Color(0xFFF5B301);

/// [stars] bhare hue sitare, baaki khali (kul 5)
class StarRow extends StatelessWidget {
  final int stars;
  final double size;
  const StarRow({super.key, required this.stars, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 1; i <= 5; i++)
          Icon(
            i <= stars ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: kStarColor,
          ),
      ],
    );
  }
}