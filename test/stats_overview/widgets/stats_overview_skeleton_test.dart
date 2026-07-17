import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/stats_overview/widgets/stats_overview_skeleton.dart';
import 'package:shimmer/shimmer.dart';

import '../../helpers/helpers.dart';

void main() {
  group('StatsOverviewSkeleton', () {
    Widget wrap({required bool isPhone}) {
      return DeviceInfoProvider(
        isPhone: isPhone,
        child: const StatsOverviewSkeleton(),
      );
    }

    testWidgets('renders a shimmer with a grid of skeleton bones',
        (tester) async {
      await tester.pumpApp(wrap(isPhone: false));

      expect(find.byType(StatsOverviewSkeleton), findsOneWidget);
      expect(find.byType(Shimmer), findsOneWidget);
      expect(find.byType(GridView), findsOneWidget);
      expect(find.byType(SkeletonBone), findsWidgets);
    });

    testWidgets('shows no CircularProgressIndicator', (tester) async {
      await tester.pumpApp(wrap(isPhone: true));

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
