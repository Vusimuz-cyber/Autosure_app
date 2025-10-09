import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
          'DefaultFirebaseOptions have not been configured for ios - ',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - ',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - ',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - ',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: "AIzaSyBlUbopuI-voJir4LyCTnyJj78xUiJnbAY",
    appId: "1:46543186421:web:6cbe036a822eb8c9b018bc",
    messagingSenderId: "46543186421",
    projectId: "autosure-66414",
    authDomain: "autosure-66414.firebaseapp.com",
    databaseURL: "https://autosure-66414-default-rtdb.firebaseio.com", // Added this line
    storageBucket: "autosure-66414.firebasestorage.app",
    measurementId: "G-XP0KEC9SVJ",
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyAhYJcWSYTmCAk_62nd0y7t7Yv8etjiZVE",
    appId: "1:46543186421:android:5c78fa9683f2d8e2b018bc",
    messagingSenderId: "46543186421",
    projectId: "autosure-66414",
    storageBucket: "autosure-66414.firebasestorage.app",
  );
}