import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  var isFirebaseReady = false;
  try {
    await Firebase.initializeApp();
    isFirebaseReady = true;
  } catch (_) {
    try {
      Firebase.app();
      isFirebaseReady = true;
    } catch (_) {
      isFirebaseReady = false;
    }
  }

  runApp(
    QrApp(
      isFirebaseReady: isFirebaseReady,
    ),
  );
}
