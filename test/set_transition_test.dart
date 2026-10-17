import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torneo_voleibol/models.dart';
import 'package:torneo_voleibol/rules.dart';
import 'package:torneo_voleibol/screens/lineup_screen.dart';
import 'package:torneo_voleibol/screens/live_game_screen.dart';
import 'package:torneo_voleibol/store.dart';

Team _equipo(String id, String nombre) => Team(
      id: id,
      nombre: nombre,
      jugadores: List.generate(
          6,
          (i) => Player(
              id: '${id}p$i', nombre: 'J$i', apellido: nombre, numero: i + 1)),
    );

void main() {
  test('Saques alternan entre sets y los lados cambian', () {
    expect(saqueDelSiguienteSet('eqA', 'eqA', 'eqB'), 'eqB');
    expect(saqueDelSiguienteSet('eqB', 'eqA', 'eqB'), 'eqA');
    expect(ladoDelSiguienteSet(false), true);
    expect(ladoDelSiguienteSet(true), false);
  });

  testWidgets('Fin del set 1: saca el otro equipo y cambian de lado',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = AppStore();
    store.torneos.add(Tournament(
      id: 't1',
      nombre: 'Copa',
      formato: Formato.dosDeTres,
      sistema: Sistema.roundRobin1,
      equipos: [_equipo('eqA', 'Alfa'), _equipo('eqB', 'Beta')],
      fixture: [Match(id: 'm1', equipoAId: 'eqA', equipoBId: 'eqB')],
    ));

    await tester.pumpWidget(ChangeNotifierProvider.value(
      value: store,
      child: MaterialApp(
        home: LiveGameScreen(
          torneoId: 't1',
          matchId: 'm1',
          ladoAId: 'eqA',
          ladoBId: 'eqB',
          saqueId: 'eqA', // Alfa abrió el saque en el set 1
          setNumero: 1,
          lineupA: const ['eqAp0', 'eqAp1', 'eqAp2', 'eqAp3', 'eqAp4', 'eqAp5'],
          lineupB: const ['eqBp0', 'eqBp1', 'eqBp2', 'eqBp3', 'eqBp4', 'eqBp5'],
        ),
      ),
    ));
    await tester.pump();

    // Alfa gana el set 1 25-0.
    final mas = find.widgetWithText(ElevatedButton, '+1').first;
    for (var i = 0; i < 25; i++) {
      await tester.tap(mas);
      await tester.pump();
    }
    expect(find.textContaining('Set 1 terminado 25-0'), findsOneWidget);
    // Saque alternado: el que abrió (Alfa) no abre el set 2.
    expect(find.textContaining('Saca Beta'), findsOneWidget);
    // Cambio de lado: Alfa pasa a la derecha, Beta a la izquierda.
    expect(
        find.textContaining('Alfa a la derecha'), findsOneWidget);
    expect(
        find.textContaining('Beta a la izquierda'), findsOneWidget);

    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.byType(LineupScreen), findsOneWidget);
    expect(find.textContaining('Arriba: Beta (saque)'), findsOneWidget);
    expect(find.textContaining('Alfa a la derecha'), findsOneWidget);
    expect(find.textContaining('Beta a la izquierda'), findsOneWidget);
  });
}
