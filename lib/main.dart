import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/messenger.dart';
import 'app/router.dart';
import 'app/theme.dart';
import 'app/theme_mode_provider.dart';
import 'core/widgets/connectivity_banner.dart';
import 'core/widgets/crash_fallback.dart';
import 'data/services/theme_storage.dart';
import 'features/notifications/notification_toaster.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Har ghalti ek jagah dikhe; baad mein Crashlytics yahan lag sakti hai.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError: ${details.exceptionAsString()}');
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error');
    return true;
  };
  if (kReleaseMode) {
    ErrorWidget.builder = (details) => const CrashFallback();
  }

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Firebase connected: ${Firebase.app().options.projectId}');
  final themeMode = await ThemeStorage.load();
  runApp(
    ProviderScope(
      overrides: [initialThemeModeProvider.overrideWithValue(themeMode)],
      child: const ParcelGoApp(),
    ),
  );
}

class ParcelGoApp extends ConsumerWidget {
  const ParcelGoApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'ParcelGo',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      scaffoldMessengerKey: rootMessengerKey,
      builder: (context, child) => NotificationToaster(
        child: ConnectivityBanner(child: child ?? const SizedBox.shrink()),
      ),
    );
  }
}
