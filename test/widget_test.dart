import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:mindease/app/app.dart';

void main() {
  testWidgets('MindEase app smoke test', (WidgetTester tester) async {
    await Hive.initFlutter();
    await tester.pumpWidget(
      const ProviderScope(child: MindEaseApp()),
    );
    await tester.pump();
  });
}
