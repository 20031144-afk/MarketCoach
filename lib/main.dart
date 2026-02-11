import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:market_coach/app/market_coach_app.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Enable offline persistence for Firestore
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  // Auto sign-in anonymously if no user is signed in
  // Ensures every app launch has a valid Firebase Auth UID
  final auth = FirebaseAuth.instance;
  if (auth.currentUser == null) {
    try {
      await auth.signInAnonymously();
      debugPrint('Auto signed in anonymously');
    } catch (e) {
      debugPrint('Failed to auto sign-in anonymously: $e');
    }
  }

  runApp(ProviderScope(child: const MarketCoachApp()));
}
