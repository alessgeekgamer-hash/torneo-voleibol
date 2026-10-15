import 'package:flutter_test/flutter_test.dart';
import 'package:torneo_voleibol/models.dart';
import 'package:torneo_voleibol/store.dart';

MatchResult res(String match, String ganador, String fecha) =>
    MatchResult(
      matchId: match,
      equipoAId: 'A',
      equipoBId: 'B',
      setsA: ganador == 'A' ? 2 : 0,
      setsB: ganador == 'B' ? 2 : 0,
      parciales: const ['25-0', '25-0'],
      ganadorId: ganador,
      fecha: fecha,
    );

void main() {
  test('Fusion une resultados y gana el más reciente', () {
    final store = AppStore();
    final local = Tournament(
        id: 'T1',
        nombre: 'T',
        formato: Formato.dosDeTres,
        sistema: Sistema.roundRobin1,
        equipos: [Team(id: 'A', nombre: 'A'), Team(id: 'B', nombre: 'B')],
        fixture: [
          Match(id: 'M1', equipoAId: 'A', equipoBId: 'B'),
          Match(id: 'M2', equipoAId: 'A', equipoBId: 'B'),
        ],
        resultados: [res('M1', 'A', '2026-01-01T10:00:00')]);
    store.torneos.add(local);

    final remoto = Tournament(
        id: 'T1',
        nombre: 'T',
        formato: Formato.dosDeTres,
        sistema: Sistema.roundRobin1,
        equipos: [Team(id: 'A', nombre: 'A'), Team(id: 'B', nombre: 'B')],
        fixture: [],
        resultados: [
          res('M1', 'B', '2026-01-02T10:00:00'), // mismo partido, más nuevo
          res('M2', 'A', '2026-01-02T11:00:00'), // partido distinto
        ]);
    final c = store.fusionarTorneo(remoto);
    expect(c['resultados'], 2);
    final m1 =
        local.resultados.firstWhere((e) => e.matchId == 'M1');
    expect(m1.ganadorId, 'B'); // ganó el más reciente
    expect(local.resultados.length, 2);
  });
}
