// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'package:analytics_repository/analytics_repository.dart';

/// {@template analytics_repository}
/// Repository which manages tracking analytics events.
/// {@endtemplate}
abstract class AnalyticsRepository {
  /// {@macro analytics_repository}
  const AnalyticsRepository();

  /// Tracks the provided [AnalyticsEvent].
  void track(AnalyticsEvent event);
}
