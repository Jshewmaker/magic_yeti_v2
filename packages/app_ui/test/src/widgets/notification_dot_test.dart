import 'package:app_ui/app_ui.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationDot', () {
    testWidgets('renders a red circle at the requested size', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: NotificationDot(size: 12))),
      );

      final container = tester.widget<Container>(find.byType(Container));
      final decoration = container.decoration! as BoxDecoration;

      expect(decoration.color, AppColors.red);
      expect(decoration.shape, BoxShape.circle);
      expect(tester.getSize(find.byType(NotificationDot)), const Size(12, 12));
    });
  });
}
