// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:magic_yeti/firebase_options.dart';

Future<void> bootstrap(
  Future<Widget> Function(
    FirebaseFirestore firestore,
  ) builder,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Bloc.observer = AppBlocObserver(
  //   analyticsRepository: analyticsRepository,
  // );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(
    await builder(FirebaseFirestore.instance),
  );
}
