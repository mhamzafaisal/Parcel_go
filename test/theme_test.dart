import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parcel_go/app/theme.dart';
import 'package:parcel_go/app/theme_mode_provider.dart';
import 'package:parcel_go/core/widgets/appearance_tile.dart';
import 'package:parcel_go/data/services/theme_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// WCAG ke hisaab se do rangon ke beech contrast
double contrast(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final hi = l1 > l2 ? l1 : l2;
  final lo = l1 > l2 ? l2 : l1;
  return (hi + 0.05) / (lo + 0.05);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const palettes = {'light': AppPalette.light, 'dark': AppPalette.dark};

  test('main text is easy to read on cards and background', () {
    palettes.forEach((name, p) {
      expect(contrast(p.ink, p.surface), greaterThanOrEqualTo(7), reason: name);
      expect(
        contrast(p.ink, p.background),
        greaterThanOrEqualTo(7),
        reason: name,
      );
    });
  });

  test('muted text is readable on cards and background', () {
    palettes.forEach((name, p) {
      expect(
        contrast(p.muted, p.surface),
        greaterThanOrEqualTo(4.5),
        reason: name,
      );
      expect(
        contrast(p.muted, p.background),
        greaterThanOrEqualTo(4),
        reason: name,
      );
    });
  });

  test('the green is visible on cards and background in both themes', () {
    palettes.forEach((name, p) {
      expect(
        contrast(AppColors.green, p.surface),
        greaterThanOrEqualTo(3),
        reason: name,
      );
      expect(
        contrast(AppColors.green, p.background),
        greaterThanOrEqualTo(3),
        reason: name,
      );
    });
  });

  test('theme mode is saved and read back as text', () {
    for (final m in ThemeMode.values) {
      expect(themeModeFromString(themeModeToString(m)), m);
    }
    expect(themeModeFromString(null), ThemeMode.system);
    expect(themeModeFromString('nonsense'), ThemeMode.system);
  });

  test('theme mode labels', () {
    expect(themeModeLabel(ThemeMode.system), 'System default');
    expect(themeModeLabel(ThemeMode.light), 'Light');
    expect(themeModeLabel(ThemeMode.dark), 'Dark');
  });

  group('saved appearance', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test('missing or unknown saved preference uses the system theme', () async {
      expect(await ThemeStorage.load(), ThemeMode.system);
      SharedPreferences.setMockInitialValues({'theme_mode': 'nonsense'});
      expect(await ThemeStorage.load(), ThemeMode.system);
    });

    test('each theme mode is persisted and loaded', () async {
      for (final mode in ThemeMode.values) {
        await ThemeStorage.save(mode);
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('theme_mode'), themeModeToString(mode));
        expect(await ThemeStorage.load(), mode);
      }
    });

    test(
      'provider starts with the saved theme and changes immediately',
      () async {
        SharedPreferences.setMockInitialValues({'theme_mode': 'dark'});
        final container = ProviderContainer(
          overrides: [
            initialThemeModeProvider.overrideWithValue(
              await ThemeStorage.load(),
            ),
          ],
        );
        addTearDown(container.dispose);

        expect(container.read(themeModeProvider), ThemeMode.dark);
        final saving = container
            .read(themeModeProvider.notifier)
            .set(ThemeMode.light);
        expect(container.read(themeModeProvider), ThemeMode.light);
        await saving;
        expect(await ThemeStorage.load(), ThemeMode.light);
      },
    );

    testWidgets(
      'appearance choices update the theme and follow system changes',
      (tester) async {
        tester.binding.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        addTearDown(
          tester.binding.platformDispatcher.clearPlatformBrightnessTestValue,
        );
        SharedPreferences.setMockInitialValues({'theme_mode': 'light'});
        final initialMode = await ThemeStorage.load();

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              initialThemeModeProvider.overrideWithValue(initialMode),
            ],
            child: Consumer(
              builder: (context, ref, _) => MaterialApp(
                theme: AppTheme.light,
                darkTheme: AppTheme.dark,
                themeMode: ref.watch(themeModeProvider),
                home: const Scaffold(body: AppearanceTile()),
              ),
            ),
          ),
        );
        expect(
          Theme.of(tester.element(find.byType(AppearanceTile))).brightness,
          Brightness.light,
        );

        for (final mode in [
          ThemeMode.dark,
          ThemeMode.light,
          ThemeMode.system,
        ]) {
          await tester.tap(find.text('Appearance'));
          await tester.pumpAndSettle();
          await tester.tap(find.text(themeModeLabel(mode)));
          await tester.pumpAndSettle();

          final tileContext = tester.element(find.byType(AppearanceTile));
          final dark = mode == ThemeMode.dark;
          expect(find.byType(BottomSheet), findsNothing);
          expect(find.text(themeModeLabel(mode)), findsOneWidget);
          expect(
            ProviderScope.containerOf(tileContext).read(themeModeProvider),
            mode,
          );
          expect(
            Theme.of(tileContext).brightness,
            dark ? Brightness.dark : Brightness.light,
          );
          expect(
            tileContext.surface,
            dark ? AppPalette.dark.surface : AppPalette.light.surface,
          );
          expect(await ThemeStorage.load(), mode);
        }

        tester.binding.platformDispatcher.platformBrightnessTestValue =
            Brightness.dark;
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.byType(AppearanceTile))).brightness,
          Brightness.dark,
        );
        tester.binding.platformDispatcher.platformBrightnessTestValue =
            Brightness.light;
        await tester.pumpAndSettle();
        expect(
          Theme.of(tester.element(find.byType(AppearanceTile))).brightness,
          Brightness.light,
        );
      },
    );
  });
}
