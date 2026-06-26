// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:magic_yeti/app/utils/scryfall_user_agent.dart';
import 'package:magic_yeti/firebase_options.dart';

Future<void> bootstrap(
  Future<Widget> Function(
    FirebaseFirestore firestore,
  ) builder,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  // Scryfall's image CDN rejects the default Dart User-Agent with HTTP 400.
  applyScryfallUserAgent();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // FlutterError.onError = (errorDetails) {
  //   FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  // };
  // Pass all uncaught asynchronous errors that aren't handled by the
  // Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    //  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Bloc.observer = AppBlocObserver();
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(
    await builder(FirebaseFirestore.instance),
  );
}
