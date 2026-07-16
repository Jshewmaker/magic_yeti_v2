import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/home/widgets/match_history_skeleton.dart';
import 'package:shimmer/shimmer.dart';

import '../../helpers/helpers.dart';

void main() {
  group('MatchHistorySkeleton', () {
    testWidgets('renders a shimmer with skeleton bones', (tester) async {
      await tester.pumpApp(const MatchHistorySkeleton());

      expect(find.byType(MatchHistorySkeleton), findsOneWidget);
      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(SkeletonBone), findsWidgets);
    });

    testWidgets('shows no CircularProgressIndicator', (tester) async {
      await tester.pumpApp(const MatchHistorySkeleton());

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('renders placeholder cards', (tester) async {
      await tester.pumpApp(const MatchHistorySkeleton(itemCount: 2));

      // At least the first card's bones are laid out without error.
      expect(find.byType(Card), findsWidgets);
    });
  });
}
