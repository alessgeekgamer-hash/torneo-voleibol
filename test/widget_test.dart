import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:torneo_voleibol/main.dart';
import 'package:torneo_voleibol/store.dart';

void main() {
  testWidgets('App arranca', (WidgetTester tester) async {
    final store = AppStore();
    await tester.pumpWidget(
        ChangeNotifierProvider.value(value: store, child: const App()));
    await tester.pump();
    expect(find.textContaining('Tournament Control'), findsOneWidget);
  });
}
