import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// To regenerate this file, run `flutterfire configure`.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // TODO: Replace these placeholder values with your actual Firebase config.
  // Run `flutterfire configure` in your terminal to auto-generate these.

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCJ_kzTLJKQYRknZdw_dFfe8wJjOqTCmCw',
    appId: '1:612502468471:android:13ca6930914bd0361f1372',
    messagingSenderId: '612502468471',
    projectId: 'splitwiser-26',
    storageBucket: 'splitwiser-26.firebasestorage.app',
  );
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCZSUUS_0B7IPEOR95DHApwrfaAKlLdhxI',
    appId: '1:612502468471:ios:c3cf93eab89349c91f1372',
    messagingSenderId: '612502468471',
    projectId: 'splitwiser-26',
    storageBucket: 'splitwiser-26.firebasestorage.app',
    iosBundleId: 'com.splitwise.app.splitWise',
  );
  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDuyxX5rTKMu9TTry3CKXNXKROYFl5E7KQ',
    appId: '1:612502468471:web:bbf98a0b7441cf051f1372',
    messagingSenderId: '612502468471',
    projectId: 'splitwiser-26',
    authDomain: 'splitwiser-26.firebaseapp.com',
    databaseURL: 'https://splitwiser-26-default-rtdb.firebaseio.com',
    storageBucket: 'splitwiser-26.firebasestorage.app',
    measurementId: 'G-0H1R9J56X7',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCZSUUS_0B7IPEOR95DHApwrfaAKlLdhxI',
    appId: '1:612502468471:ios:f1c4c08378d25c831f1372',
    messagingSenderId: '612502468471',
    projectId: 'splitwiser-26',
    storageBucket: 'splitwiser-26.firebasestorage.app',
    iosBundleId: 'com.splitwise.app.splitW',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyDuyxX5rTKMu9TTry3CKXNXKROYFl5E7KQ',
    appId: '1:612502468471:web:9c248138240df0371f1372',
    messagingSenderId: '612502468471',
    projectId: 'splitwiser-26',
    authDomain: 'splitwiser-26.firebaseapp.com',
    databaseURL: 'https://splitwiser-26-default-rtdb.firebaseio.com',
    storageBucket: 'splitwiser-26.firebasestorage.app',
    measurementId: 'G-KJQR4J8CE3',
  );
}
