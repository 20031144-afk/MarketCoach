import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Placeholder Firebase options so the app compiles before you run `flutterfire configure`.
/// Replace this file with the generated one from `flutterfire configure --project marketcoach-db8f4`.
class DefaultFirebaseOptions {
  static FirebaseOptions? get currentPlatform {
    if (kIsWeb) return web;

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      default:
        return null;
    }
  }

  static const FirebaseOptions? web = null;
  static const FirebaseOptions? android = null;
  static const FirebaseOptions? ios = null;
  static const FirebaseOptions? macos = null;
  static const FirebaseOptions? windows = null;
  static const FirebaseOptions? linux = null;
}
