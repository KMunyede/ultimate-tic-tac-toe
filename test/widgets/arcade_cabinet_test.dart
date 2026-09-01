// test/widgets/arcade_cabinet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tictactoe/widgets/arcade/arcade_cabinet_frame.dart';

void main() {
  testWidgets('ArcadeCabinetFrame renders child and bezel elements', (WidgetTester tester) async {
    const testKey = Key('content');
    
    await tester.pumpWidget(
      const MaterialApp(
        home: ArcadeCabinetFrame(
          child: SizedBox(key: testKey, width: 100, height: 100),
        ),
      ),
    );

    // Verify child is rendered
    expect(find.byKey(testKey), findsOneWidget);

    // Verify presence of custom painted elements (screws) via CustomPaint finder
    expect(find.byType(CustomPaint), findsAtLeastNWidgets(4)); // 4 screws + 1 scanline overlay
  });
}
