import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

import '../../app/theme.dart';

class ThemedTileLayer extends StatelessWidget {
  final String urlTemplate;
  final String userAgentPackageName;

  const ThemedTileLayer({
    super.key,
    required this.urlTemplate,
    required this.userAgentPackageName,
  });

  @override
  Widget build(BuildContext context) {
    final layer = TileLayer(
      urlTemplate: urlTemplate,
      userAgentPackageName: userAgentPackageName,
    );
    if (!context.isDark) return layer;
    return ColorFiltered(
      colorFilter: ColorFilter.matrix(<double>[
        -1, 0, 0, 0, 255, //
        0, -1, 0, 0, 255, //
        0, 0, -1, 0, 255, //
        0, 0, 0, 1, 0, //
      ]),
      child: layer,
    );
  }
}
