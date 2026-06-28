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
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not configured for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAjXbkhrPPgq9hwlhdKB21dG2VfvatAXTI',
    appId: '1:1086152719549:web:199b8c17ac57081cda0bd4',
    messagingSenderId: '1086152719549',
    projectId: 'shield-zabnix',
    authDomain: 'shield-zabnix.firebaseapp.com',
    storageBucket: 'shield-zabnix.firebasestorage.app',
    measurementId: 'G-358541Z4LN',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCvtCMGyaE0M2ztkvMOlEwrgrDjkulesZQ',
    appId: '1:1086152719549:android:b63fc70829f7da89da0bd4',
    messagingSenderId: '1086152719549',
    projectId: 'shield-zabnix',
    storageBucket: 'shield-zabnix.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCArupIVrLhMSgRzjUT1L5akfsyjxbFv0I',
    appId: '1:1086152719549:ios:6eaaa0448771089bda0bd4',
    messagingSenderId: '1086152719549',
    projectId: 'shield-zabnix',
    storageBucket: 'shield-zabnix.firebasestorage.app',
    iosBundleId: 'com.zabnix.shield',
    iosClientId:
        '1086152719549-pc7sti6p3n05i8e3v56njpj9f8qmj2k1.apps.googleusercontent.com',
  );
}
