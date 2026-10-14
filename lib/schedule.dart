import 'models.dart';

/// Genera rol de juegos según sistema.
List<Match> generarFixture(List<Team> equipos, Sistema sistema) {
  final ids = equipos.map((e) => e.id).toList();
  if (ids.length < 2) return [];
  if (sistema == Sistema.eliminacionDirecta) {
    return _directa(ids);
  }
  final una = _roundRobin(ids, 1);
  if (sistema == Sistema.roundRobin1) return una;
  final dos = _roundRobin(ids, 2, invertir: true);
  return [...una, ...dos];
}

List<Match> _roundRobin(List<String> ids, int vuelta,
    {bool invertir = false}) {
  final list = List<String>.from(ids);
  final impar = list.length.isOdd;
  if (impar) list.add('BYE');
  final n = list.length;
  final rondas = n - 1;
  final mitad = n ~/ 2;
  final out = <Match>[];
  final rot = List<String>.from(list);
  for (var r = 0; r < rondas; r++) {
    for (var i = 0; i < mitad; i++) {
      final a = rot[i];
      final b = rot[n - 1 - i];
      if (a == 'BYE' || b == 'BYE') continue;
      final x = invertir ? b : a;
      final y = invertir ? a : b;
      out.add(Match(
          equipoAId: x,
          equipoBId: y,
          vuelta: vuelta,
          etiqueta: 'J${r + 1}'));
    }
    // rotar (mantener primero fijo)
    final ultimo = rot.removeLast();
    rot.insert(1, ultimo);
  }
  return out;
}

List<Match> _directa(List<String> ids) {
  final out = <Match>[];
  // Si es potencia de 2 se empareja directo, si no, se generan play-in simples.
  final list = List<String>.from(ids);
  var ronda = 1;
  // Primera ronda: emparejar consecutivos
  for (var i = 0; i + 1 < list.length; i += 2) {
    out.add(Match(
        equipoAId: list[i],
        equipoBId: list[i + 1],
        vuelta: ronda,
        etiqueta: 'Ronda $ronda'));
  }
  if (list.length.isOdd) {
    // último pasa bye: se representa como partido pendiente que se creará
    // al avanzar; por ahora no se crea partido.
  }
  return out;
}

/// Al guardar un resultado en eliminación directa, genera la siguiente ronda
/// cuando todos los partidos de la ronda actual están jugados.
List<Match> avanzarDirecta(Tournament t) {
  if (t.sistema != Sistema.eliminacionDirecta) return [];
  // agrupar por vuelta
  final porVuelta = <int, List<Match>>{};
  for (final m in t.fixture) {
    porVuelta.putIfAbsent(m.vuelta, () => []).add(m);
  }
  if (porVuelta.isEmpty) return [];
  final ultima = porVuelta.keys.reduce((a, b) => a > b ? a : b);
  final partidos = porVuelta[ultima]!;
  // si falta algún resultado, no avanzar
  for (final p in partidos) {
    final jugado =
        t.resultados.any((r) => r.matchId == p.id);
    if (!jugado) return [];
  }
  if (partidos.length <= 1) return []; // campeón
  // ganadores en orden
  final ganadores = <String>[];
  for (final p in partidos) {
    final r = t.resultados.firstWhere((e) => e.matchId == p.id);
    ganadores.add(r.ganadorId);
  }
  final nuevos = <Match>[];
  for (var i = 0; i + 1 < ganadores.length; i += 2) {
    nuevos.add(Match(
        equipoAId: ganadores[i],
        equipoBId: ganadores[i + 1],
        vuelta: ultima + 1,
        etiqueta: ganadores.length == 2 ? 'Final' : 'Ronda ${ultima + 1}'));
  }
  // si impar, el último avanza directo (bye) -> se guarda como partido
  // fantasma? Lo dejamos pendiente: se creará cuando haya rival.
  return nuevos;
}
