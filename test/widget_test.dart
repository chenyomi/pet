import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_pet/src/app.dart';

void main() {
  testWidgets('app loads pet screen', (WidgetTester tester) async {
    await tester.pumpWidget(const DigiPetApp());

    expect(find.byType(DigiPetApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
