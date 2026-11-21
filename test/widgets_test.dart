import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_go/app/theme.dart';
import 'package:parcel_go/core/widgets/connectivity_banner.dart';
import 'package:parcel_go/core/widgets/error_view.dart';
import 'package:parcel_go/core/widgets/primary_button.dart';
import 'package:parcel_go/core/widgets/status_chip.dart';
import 'package:parcel_go/data/models/shipment.dart';
import 'package:parcel_go/data/services/connectivity_service.dart';

Widget wrap(Widget child) => MaterialApp(
  theme: AppTheme.light,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('ErrorView shows a friendly message and retries', (tester) async {
    var retried = 0;
    await tester.pumpWidget(
      wrap(ErrorView(error: TimeoutException('x'), onRetry: () => retried++)),
    );

    expect(find.textContaining('taking too long'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    expect(retried, 1);
  });

  testWidgets('PrimaryButton shows a spinner and ignores taps while loading', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      wrap(
        PrimaryButton(label: 'Pay', isLoading: true, onPressed: () => taps++),
      ),
    );

    expect(find.text('Pay'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(find.byType(ElevatedButton));
    expect(taps, 0);
  });

  testWidgets('StatusChip shows the label of every status', (tester) async {
    for (final s in ShipmentStatus.values) {
      await tester.pumpWidget(wrap(StatusChip(status: s)));
      expect(find.text(s.label), findsOneWidget);
    }
  });

  testWidgets('ConnectivityBanner is hidden online and shown offline', (
    tester,
  ) async {
    final connectivity = StreamController<bool>();
    addTearDown(connectivity.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isOnlineProvider.overrideWith((ref) => connectivity.stream),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: const Scaffold(
            body: ConnectivityBanner(child: Text('content')),
          ),
        ),
      ),
    );

    connectivity.add(true);
    await tester.pump();
    expect(find.text('content'), findsOneWidget);
    expect(find.textContaining('You are offline'), findsNothing);

    connectivity.add(false);
    await tester.pumpAndSettle();
    expect(find.textContaining('You are offline'), findsOneWidget);
    expect(find.text('content'), findsOneWidget);

    connectivity.add(true);
    await tester.pumpAndSettle();
    expect(find.textContaining('You are offline'), findsNothing);
    expect(find.text('content'), findsOneWidget);
  });
}
