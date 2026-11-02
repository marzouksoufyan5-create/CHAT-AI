import 'package:flutter_test/flutter_test.dart';
import 'package:chat_ai/main.dart';

void main() {
  testWidgets('CHAT AI home screen renders', (tester) async {
    await tester.pumpWidget(const ChatAiApp());

    expect(find.text('CHAT AI'), findsOneWidget);
    expect(find.text('مرحباً بك في CHAT AI'), findsOneWidget);
    expect(find.text('اكتشف الأدوات'), findsOneWidget);
  });
}
