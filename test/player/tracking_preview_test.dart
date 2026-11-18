import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:magic_yeti/player/view/widgets/tracking_preview.dart';

void main() {
  testWidgets('shows clock count and a pip per color', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TrackingPreview(
            damageClocks: 2,
            colorIdentity: ['W', 'U', 'B'],
          ),
        ),
      ),
    );

    expect(find.text('2 commander-damage clocks'), findsOneWidget);
    expect(
      find.byKey(const Key('tracking_preview_pips')),
      findsOneWidget,
    );
  });

  testWidgets('uses singular label for one clock', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: TrackingPreview(damageClocks: 1, colorIdentity: []),
        ),
      ),
    );
    expect(find.text('1 commander-damage clock'), findsOneWidget);
  });
}
