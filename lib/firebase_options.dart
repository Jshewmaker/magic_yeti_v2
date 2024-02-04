// File generated by FlutterFire CLI.
// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD_no1k3ser82hig8jyh1xKEszi7KZNS9s',
    appId: '1:621633361811:web:a7244534866aeb9bf57a66',
    messagingSenderId: '621633361811',
    projectId: 'mtg-yeti',
    authDomain: 'mtg-yeti.firebaseapp.com',
    storageBucket: 'mtg-yeti.appspot.com',
    measurementId: 'G-LKQSKBV3PR',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAJi9ttHg0HYpCP1K_ag3ZxFoHuIqHI2WA',
    appId: '1:621633361811:android:275ff956820ed375f57a66',
    messagingSenderId: '621633361811',
    projectId: 'mtg-yeti',
    storageBucket: 'mtg-yeti.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBCgxhw8rYb-Pw0QBxozi94OkUUpcTftss',
    appId: '1:621633361811:ios:bea39277eece8d75f57a66',
    messagingSenderId: '621633361811',
    projectId: 'mtg-yeti',
    storageBucket: 'mtg-yeti.appspot.com',
    iosClientId: '621633361811-b9n6sac53ht8a9hunsr3r6k79vaij7la.apps.googleusercontent.com',
    iosBundleId: 'com.crossout.org.magic-yeti',
  );
}
