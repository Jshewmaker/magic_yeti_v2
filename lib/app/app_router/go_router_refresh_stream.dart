// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:magic_yeti/app/bloc/app_bloc.dart';

/// {@template go_router_refresh_stream}
/// Class that converts a [Stream] into a [Listenable].
///
/// {@endtemplate}
class GoRouterRefreshStream extends ValueNotifier<AppStatus?> {
  /// Creates a [GoRouterRefreshStream].
  ///
  /// Every time the [stream] receives a change in the status,
  /// the GoRouter will [notifyListeners].
  GoRouterRefreshStream(Stream<AppState> stream) : super(null) {
    _subscription = stream.asBroadcastStream().listen((state) {
      value = state.status;
    });
  }

  late final StreamSubscription<AppState> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
