import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:onecard_game/presentation/app.dart';

void main() {
  testWidgets('Home screen smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: OneCardApp(),
      ),
    );

    // Verify that our home screen is loaded.
    expect(find.text('원카드 게임'), findsOneWidget);
    expect(find.text('게임 시작'), findsOneWidget);
  });
}
