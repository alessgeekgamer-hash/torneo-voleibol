import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torneo_voleibol/models.dart';
import 'package:torneo_voleibol/server/results_server.dart';
import 'package:torneo_voleibol/store.dart';

void main() {
  test('Servidor, descarga y subida de punta a punta', () async {
    SharedPreferences.setMockInitialValues({});
    final central = AppStore();
    final t = Tournament(
        id: 'T1',
        nombre: 'Copa',
        formato: Formato.dosDeTres,
        sistema: Sistema.roundRobin1,
        equipos: [
          Team(id: 'A', nombre: 'Tigres', jugadores: [
            Player(id: 'J1', nombre: 'Ana', apellido: 'López', numero: 7)
          ]),
          Team(id: 'B', nombre: 'Panteras'),
        ],
        fixture: [Match(id: 'M1', equipoAId: 'A', equipoBId: 'B')],
        resultados: [
          MatchResult(
              matchId: 'M1',
              equipoAId: 'A',
              equipoBId: 'B',
              setsA: 2,
              setsB: 0,
              parciales: const ['25-10', '25-12'],
              ganadorId: 'A',
              fecha: '2026-10-15T10:00:00',
              lugar: 'Cancha 1',
              tiemposA: [1, 0],
              tiemposB: [1, 1],
              cambiosA: [2, 1],
              cambiosB: [0, 0],
              jugadoresA: [PlayerSnapshot(nombre: 'Ana López', numero: 7)],
              jugadoresB: []),
        ]);
    central.torneos.add(t);

    final srv = ResultsServer.instance;
    expect(await srv.start(central, port: 18081), true);
    try {
      // Descarga en equipo vacío.
      final movil = AppStore();
      final msg = await movil.descargarDe('  http://127.0.0.1:18081/ ');
      expect(movil.torneos.length, 1);
      expect(movil.torneos.first.nombre, 'Copa');
      expect(movil.torneos.first.equipos.length, 2);
      expect(movil.torneos.first.resultados.length, 1);
      expect(
          movil.torneos.first.resultados.first.jugadoresA.first.numero,
          7);
      expect(msg.contains('Descargados'), true);

      // El móvil agrega un resultado y lo sube.
      movil.torneos.first.resultados.add(MatchResult(
          matchId: 'M2',
          equipoAId: 'A',
          equipoBId: 'B',
          setsA: 0,
          setsB: 2,
          parciales: const ['20-25', '22-25'],
          ganadorId: 'B',
          fecha: '2026-10-15T12:00:00'));
      await movil.setServerUrl('http://127.0.0.1:18081');
      final up = await movil.sincronizar();
      expect(up.contains('Sincronizado'), true);
      expect(central.torneos.first.resultados.length, 2);
    } finally {
      await srv.stop();
    }
  });
}
