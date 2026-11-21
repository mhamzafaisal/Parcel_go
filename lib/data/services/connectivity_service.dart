import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// connectivity_plus ke naye (list) aur purane (ek value) dono versions ke liye.
bool connectivityIsOnline(Object result) {
  if (result is List) {
    return result.any((r) => r != ConnectivityResult.none);
  }
  return result != ConnectivityResult.none;
}

/// Device ka network hai ya nahi (internet asal mein chal raha hai ye nahi).
final isOnlineProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  yield connectivityIsOnline(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(connectivityIsOnline);
});
