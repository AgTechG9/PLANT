import 'package:flutter_test/flutter_test.dart';
import 'package:plant_app/main.dart';

void main() {
  testWidgets('App launches and shows login screen', (WidgetTester tester) async {
    await tester.pumpWidget(const PlantApp());
    expect(find.text('PLANT'), findsOneWidget);
  });
}
