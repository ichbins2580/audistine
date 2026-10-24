import 'package:flutter_test/flutter_test.dart';
import 'package:audistine/main.dart';

void main() {
  testWidgets('AudistineApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const AudistineApp());
    expect(find.byType(AudistineApp), findsOneWidget);
  });
}
