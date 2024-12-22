// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

import 'package:analytics_repository/analytics_repository.dart';
import 'package:flutter_test/flutter_test.dart';

// AnalyticsRepository is exported and can be implemented
class _FakeAnalyticsRepository extends AnalyticsRepository {
  @override
  void track(AnalyticsEvent event) {}
}

void main() {
  group('AnalyticsRepository', () {
    test('can be instantiated', () {
      expect(_FakeAnalyticsRepository.new, returnsNormally);
    });
  });
}
