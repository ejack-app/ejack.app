import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ejack/main.dart';

void main() {
  testWidgets('App boots without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: EjackApp()));
    // Bootstrap runs after first frame; a CircularProgressIndicator
    // is rendered while auth state is being restored.
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
