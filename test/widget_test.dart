import 'package:flutter_test/flutter_test.dart';
import 'package:canasta/app/app.dart';

void main() {
  testWidgets('CanastaApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CanastaApp());
    await tester.pump(const Duration(milliseconds: 4000));
    expect(find.byType(CanastaApp), findsOneWidget);
  });
}
