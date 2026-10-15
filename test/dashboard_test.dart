import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:torneo_voleibol/models.dart';
import 'package:torneo_voleibol/screens/dashboard.dart';
import 'package:torneo_voleibol/store.dart';

void main() {
  testWidgets('Dashboard muestra los 7 recuadros de colores',
      (WidgetTester tester) async {
    final store = AppStore();
    final torneo = Tournament(
        nombre: 'Prueba',
        formato: Formato.dosDeTres,
        sistema: Sistema.roundRobin1);
    torneo.equipos.addAll([Team(nombre: 'A'), Team(nombre: 'B')]);
    store.torneos.add(torneo);

    // Viewport alto para que el grid construya los 7 recuadros a la vez.
    tester.view.physicalSize = const Size(1080, 4000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: store,
        child: MaterialApp(
            home: DashboardScreen(torneoId: torneo.id))));
    await tester.pump();

    for (final label in [
      'Rol de juegos',
      'Jornada actual',
      'Estadísticas',
      'Posiciones',
      'Historial',
      'Editar torneo',
      'Ver en red'
    ]) {
      // skipOffstage: el grid virtualiza y algunos recuadros están fuera
      // de pantalla hasta hacer scroll.
      expect(find.text(label, skipOffstage: false), findsOneWidget);
    }
    // Recuadros con degradado presentes (uno por apartado + banner).
    final cajas = tester
        .widgetList<Container>(find.byType(Container))
        .where((w) =>
            w.decoration is BoxDecoration &&
            (w.decoration as BoxDecoration).gradient is LinearGradient)
        .toList();
    expect(cajas.length, greaterThanOrEqualTo(7));
  });
}
