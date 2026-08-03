// File generated normally by the FlutterFire CLI (`flutterfire configure`).
//
// ⚠️ THIS IS A PLACEHOLDER. The app will compile with this file, but
// Firebase.initializeApp() will fail at runtime until you replace the
// values below with your real project's config. See README.md,
// section "Firebase setup", for the exact steps — in short:
//
//   1. dart pub global activate flutterfire_cli
//   2. flutterfire configure
//
// That command talks to your Firebase project and OVERWRITES this
// file with correct, real values for whichever platforms you select
// (Android is all this project needs for the coursework build).

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS — '
          'run `flutterfire configure` to add an iOS config if you need it.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // TODO: Replace every value below by running `flutterfire configure`.

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCuqkWHZUOwmGi4Bo5cWCITVou5b-X5sko',
    appId: '1:350268247024:android:9d77968d1a844ca583eb35',
    messagingSenderId: '350268247024',
    projectId: 'pharmconnect-76495',
    storageBucket: 'pharmconnect-76495.firebasestorage.app',
  );
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDIboH1FkQZD0eGerjT3Wda603kmKD9W7w',
    appId: '1:350268247024:web:0d974f88cc96a9a083eb35',
    messagingSenderId: '350268247024',
    projectId: 'pharmconnect-76495',
    authDomain: 'pharmconnect-76495.firebaseapp.com',
    storageBucket: 'pharmconnect-76495.firebasestorage.app',
    measurementId: 'G-GL644D04T6',
  );
}
