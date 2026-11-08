import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/widgets/main_shell.dart';
import '../data/models/app_user.dart';
import '../data/repositories/user_repository.dart';
import '../features/auth/auth_providers.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/onboarding_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/auth/role_select_screen.dart';
import '../features/auth/splash_screen.dart';
import '../features/customer/history/history_screen.dart';
import '../features/customer/home/home_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/rider/home/rider_home_screen.dart';
import '../features/customer/create_shipment/current_location_screen.dart';
import '../features/customer/create_shipment/create_shipment_screen.dart';
import '../features/customer/create_shipment/location_picker_screen.dart';
import '../features/customer/create_shipment/parcel_details_screen.dart';
import '../features/customer/create_shipment/shipment_summary_screen.dart';
import '../features/customer/create_shipment/booking_confirmed_screen.dart';
import '../features/customer/create_shipment/payment_screen.dart';
import '../core/widgets/rider_shell.dart';
import '../features/rider/earnings/rider_earnings_screen.dart';
import '../features/rider/profile/rider_profile_screen.dart';
import '../data/services/job_matching.dart';
import '../features/rider/jobs/job_request_screen.dart';
import '../features/rider/delivery/delivery_screen.dart';
/// Login ya profile badalte hi router ko dobara check karwata hai
class _RouterRefresh extends ChangeNotifier {
  _RouterRefresh(Ref ref) {
    ref.listen(authStateProvider, (prev, next) => notifyListeners());
    ref.listen(appUserProvider, (prev, next) => notifyListeners());
  }
}
 
const _publicRoutes = ['/splash', '/onboarding', '/login', '/otp'];
const _authFlowRoutes = ['/login', '/otp', '/role-select'];

const _customerOnlyRoutes = [
  '/home',
  '/history',
  '/profile',
  '/create-shipment',
  '/pick-location',
  '/parcel-details',
  '/shipment-summary',
  '/payment',
  '/booking-confirmed',
];

String? _redirect(Ref ref, String loc) {
  final auth = ref.read(authStateProvider);
  final profileAsync = ref.read(appUserProvider);
  final atSplash = loc == '/splash';
 
  // 1. Firebase abhi check kar raha hai ke login hai ya nahi
  if (auth.isLoading) return atSplash ? null : '/splash';
 
  // 2. Logged out
  final firebaseUser = auth.value;
  if (firebaseUser == null) {
    return _publicRoutes.contains(loc) ? null : '/login';
  }
 
  // 3. Splash aur onboarding apna kaam khud karte hain
  if (atSplash || loc == '/onboarding') return null;
 
  // 4. Profile load ho raha hai
  if (profileAsync.isLoading) {
    return _authFlowRoutes.contains(loc) ? null : '/splash';
  }
 
  // 5. Profile load nahi ho saka (network wagera): abhi kuch nahi karte
  if (profileAsync.hasError) return null;
 
  // 6. Login hai magar profile nahi bani
  final profile = profileAsync.value;
  if (profile == null) {
    return loc == '/role-select' ? null : '/role-select';
  }
 
  // 7. Role ke hisaab se
  final home = UserRepository.homeRouteFor(profile);
  if (_authFlowRoutes.contains(loc)) return home;
 
  if (profile.role == UserRole.customer && loc.startsWith('/rider')) {
    return home;
}
  if (profile.role == UserRole.rider && _customerOnlyRoutes.contains(loc)) {
    return home;
  }
  return null;
}
 
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _RouterRefresh(ref);
  ref.onDispose(refresh.dispose);
 
  final router = GoRouter(
    initialLocation: '/splash',
    refreshListenable: refresh,
    redirect: (context, state) => _redirect(ref, state.matchedLocation),
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/otp',
        builder: (context, state) {
          final args = state.extra;
          if (args is! OtpArgs) return const LoginScreen();
          return OtpScreen(args: args);
        },
      ),
      GoRoute(
        path: '/role-select',
        builder: (context, state) => const RoleSelectScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            RiderShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/rider-home',
              builder: (context, state) => const RiderHomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/rider-earnings',
              builder: (context, state) => const RiderEarningsScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/rider-profile',
              builder: (context, state) => const RiderProfileScreen(),
            ),
          ]),
        ],
      ),
      GoRoute(
        path: '/map-test',
        builder: (context, state) => const CurrentLocationScreen(),
      ),
      GoRoute(
        path: '/rider-job-request',
        redirect: (context, state) =>
            state.extra is NearbyJob ? null : '/rider-home',
        builder: (context, state) =>
            JobRequestScreen(nearby: state.extra as NearbyJob),
      ),
      GoRoute(
        path: '/rider-delivery',
        builder: (context, state) => const DeliveryScreen(),
      ),
      GoRoute(
        path: '/create-shipment',
        builder: (context, state) => const CreateShipmentScreen(),
      ),
      GoRoute(
        path: '/pick-location',
        builder: (context, state) {
          final args = state.extra;
          return LocationPickerScreen(
            args: args is PickerArgs
                ? args
                : const PickerArgs(title: 'Choose location'),
          );
        },
      ),
      GoRoute(
        path: '/parcel-details',
        builder: (context, state) => const ParcelDetailsScreen(),
      ),
      GoRoute(
        path: '/shipment-summary',
        builder: (context, state) => const ShipmentSummaryScreen(),
      ),
      GoRoute(
        path: '/payment',
        builder: (context, state) => const PaymentScreen(),
      ),
      GoRoute(
        path: '/booking-confirmed',
        redirect: (context, state) =>
            state.extra is BookingConfirmation ? null : '/home',
        builder: (context, state) =>
            BookingConfirmedScreen(data: state.extra as BookingConfirmation),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/home',
              builder: (context, state) => const HomeScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/history',
              builder: (context, state) => const HistoryScreen(),
            ),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(
              path: '/profile',
              builder: (context, state) => const ProfileScreen(),
            ),
          ]),
        ],
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});