import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BadgedIconButton', () {
    testWidgets('shows the dot when showBadge is true', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgedIconButton(
              icon: Icons.people,
              showBadge: true,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(NotificationDot), findsOneWidget);
    });

    testWidgets('hides the dot when showBadge is false', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgedIconButton(
              icon: Icons.people,
              onPressed: () {},
            ),
          ),
        ),
      );

      expect(find.byType(NotificationDot), findsNothing);
    });

    testWidgets('the dot does not steal taps from the button', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BadgedIconButton(
              icon: Icons.people,
              showBadge: true,
              onPressed: () => taps++,
            ),
          ),
        ),
      );

      // Tap the dot itself, not the icon's centre: the dot overlaps the
      // button's tap target, and without IgnorePointer this exact spot
      // would be dead.
      await tester.tapAt(tester.getCenter(find.byType(NotificationDot)));
      expect(taps, 1);
    });
  });
}
