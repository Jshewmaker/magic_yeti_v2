import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shimmer/shimmer.dart';

void main() {
  group('SkeletonBone', () {
    testWidgets('renders with given dimensions', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonBone(width: 100, height: 20),
          ),
        ),
      );

      expect(find.byType(SkeletonBone), findsOneWidget);
    });

    testWidgets('renders a circle when shape is circle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SkeletonBone(
              width: 40,
              height: 40,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
    });
  });

  group('AppShimmer', () {
    testWidgets('wraps child in a Shimmer when enabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppShimmer(
              child: SkeletonBone(width: 100, height: 20),
            ),
          ),
        ),
      );

      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(SkeletonBone), findsOneWidget);
    });

    testWidgets('renders child without Shimmer when disabled', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppShimmer(
              enabled: false,
              child: SkeletonBone(width: 100, height: 20),
            ),
          ),
        ),
      );

      expect(find.byType(Shimmer), findsNothing);
      expect(find.byType(SkeletonBone), findsOneWidget);
    });
  });
}
