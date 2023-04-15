import 'package:connection_status/connection_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  //test connectivity status

  testWidgets('Test w/ builder param', (WidgetTester tester) async {
    await tester.pumpWidget(MaterialApp(
      home: ConnectionWidget(
        builder: (BuildContext context, bool val) =>
            const Text('builder_result'),
      ),
    ));
    await tester.pump();
    expect(find.text('builder_result'), findsOneWidget);
  });
}
