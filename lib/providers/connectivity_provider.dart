import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Provider for network connectivity status
///
/// Returns true when connected to network, false when offline.
/// Updates in real-time as connectivity changes.
final connectivityProvider = StreamProvider<bool>((ref) {
  return Connectivity().onConnectivityChanged.map(
    (result) {
      // connectivity_plus v5.0.2 returns a single ConnectivityResult, not a list
      return result != ConnectivityResult.none;
    },
  );
});
