// Copyright (c) 2024, Very Good Ventures
// https://verygood.ventures

// ignore_for_file: prefer_const_constructors
import 'package:analytics_repository/analytics_repository.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_test/flutter_test.dart';

class _TestEvent extends Equatable with AnalyticsEventMixin {
  const _TestEvent({required this.id});

  final String id;

  @override
  AnalyticsEvent get event {
    return AnalyticsEvent(
      '_TestEvent',
      properties: <String, String>{'test-key': id},
    );
  }
}

void main() {
  group('AnalyticsEventMixin', () {
    const id = 'mock-id';
    test('uses value equality', () {
      expect(_TestEvent(id: id), equals(_TestEvent(id: id)));
    });
  });
}
