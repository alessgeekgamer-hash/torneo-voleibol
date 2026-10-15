import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models.dart';
import 'schedule.dart';

class StatRow {
  String equipoId;
  int pj = 0, pg = 0, pp = 0;
  int sf = 0, sc = 0, pf = 0, pc = 0;
  StatRow(this.equipoId);
  int get difSets => sf - sc;
  int get difPuntos => pf - pc;
}

class AppStore extends ChangeNotifier {
  List<Tournament> torneos = [];
  bool oscuro = false;
  bool _cargado = false;
  Map<String, PausaPartido> pausas = {};
  String serverUrl = '';

  String _pausaKey(String torneoId, String matchId) => '${torneoId}_$matchId';

  Future<void> cargar() async {
    if (_cargado) return;
    final p = await SharedPreferences.getInstance();
    oscuro = p.getBool('oscuro') ?? false;
    serverUrl = p.getString('centralUrl') ?? '';
    final raw = p.getString('torneos');
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List)
            .map((e) => Tournament.fromJson(Map<String, dynamic>.from(e)))
            .toList();
        torneos = list;
      } catch (_) {}
    }
    final rawP = p.getString('pausas');    if (rawP != null && rawP.isNotEmpty) {
      try {
        final m = Map<String, dynamic>.from(jsonDecode(rawP));
        pausas = m.map((k, v) =>
            MapEntry(k, PausaPartido.fromJson(Map<String, dynamic>.from(v))));
      } catch (_) {}
    }
    _cargado = true;
    notifyListeners();
  }

  Future<void> _guardar() async {
    final p = await SharedPreferences.getInstance();
    await p.setString(
        'torneos', jsonEncode(torneos.map((e) => e.toJson()).toList()));
    await p.setBool('oscuro', oscuro);
    await p.setString('centralUrl', serverUrl);
    await p.setString(
        'pausas', jsonEncode(pausas.map((k, v) => MapEntry(k, v.toJson()))));
  }

  Future<void> toggleOscuro() async {
    oscuro = !oscuro;
    notifyListeners();
    await _guardar();
  }

  Tournament? porId(String id) {
    try {
      return torneos.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> agregarTorneo(Tournament t) async {
    torneos.add(t);
    notifyListeners();
    await _guardar();
  }

  Future<void> eliminarTorneo(String id) async {
    torneos.removeWhere((e) => e.id == id);
    notifyListeners();
    await _guardar();
  }

  Future<void> persistir() async {
    notifyListeners();
    await _guardar();
  }

  /// Regenera fixture si está vacío.
  Future<void> asegurarFixture(Tournament t) async {
    if (t.fixture.isEmpty && t.equipos.length >= 2) {
      t.fixture = generarFixture(t.equipos, t.sistema);
      await persistir();
    }
  }

  /// Si se agrega un equipo nuevo con torneo iniciado: agrega partidos
  /// pendientes contra los demás (RR) o lo deja para la siguiente ronda
  /// en directa.
  Future<void> agregarEquipoATorneo(Tournament t, Team equipo) async {
    t.equipos.add(equipo);
    if (t.sistema == Sistema.roundRobin1 ||
        t.sistema == Sistema.roundRobin2) {
      final vueltas =
          t.sistema == Sistema.roundRobin2 ? [1, 2] : [1];
      for (final v in vueltas) {
        for (final otro in t.equipos) {
          if (otro.id == equipo.id) continue;
          final existe = t.fixture.any((m) =>
              m.vuelta == v &&
              ((m.equipoAId == equipo.id && m.equipoBId == otro.id) ||
                  (m.equipoAId == otro.id && m.equipoBId == equipo.id)));
          if (!existe) {
            t.fixture.add(Match(
                equipoAId: equipo.id,
                equipoBId: otro.id,
                vuelta: v,
                etiqueta: 'Extra'));
          }
        }
      }
    } else {
      // directa: si hay ronda abierta sin jugar, no tocamos; el equipo
      // entrará en la siguiente ronda generada si hay hueco impar.
      // Para hacerlo visible de inmediato, creamos un partido extra
      // pendiente en la última vuelta si hay número impar.
      final porVuelta = <int, List<Match>>{};
      for (final m in t.fixture) {
        porVuelta.putIfAbsent(m.vuelta, () => []).add(m);
      }
      final ultima =
          porVuelta.isEmpty ? 1 : porVuelta.keys.reduce((a, b) => a > b ? a : b);
      t.fixture.add(Match(
          equipoAId: equipo.id,
          equipoBId: t.equipos.first.id == equipo.id
              ? (t.equipos.length > 1 ? t.equipos.first.id : equipo.id)
              : t.equipos.first.id,
          vuelta: ultima,
          etiqueta: 'Extra'));
    }
    await persistir();
  }

  Future<void> guardarResultado(
      Tournament t, Match match, MatchResult r,
      {bool replicar = true}) async {
    t.resultados.removeWhere((e) => e.matchId == match.id);
    // si ya existía resultado para otro emparejamiento duplicado, se mantiene
    t.resultados.add(r);
    match.jugado = true;
    match.programado = false;
    pausas.remove(_pausaKey(t.id, match.id));
    // avanzar directa si aplica
    final nuevos = avanzarDirecta(t);
    t.fixture.addAll(nuevos);
    await persistir();
    // Replica al equipo central si hay conexión configurada.
    if (replicar) unawaited(sincronizar());
  }

  Future<void> setServerUrl(String url) async {
    serverUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    await persistir();
  }

  /// Fusiona un torneo remoto en el local (unión por id; en resultados
  /// del mismo partido gana el más reciente). Devuelve conteos.
  Map<String, int> fusionarTorneo(Tournament remoto) {
    var equiposNuevos = 0;
    var resultadosNuevos = 0;
    var local = porId(remoto.id);
    if (local == null) {
      torneos.add(remoto);
      notifyListeners();
      return {
        'equipos': remoto.equipos.length,
        'resultados': remoto.resultados.length
      };
    }
    for (final eq in remoto.equipos) {
      final le = local.equipoPorId(eq.id);
      if (le == null) {
        local.equipos.add(eq);
        equiposNuevos++;
      } else {
        // Jugadores nuevos o actualizados (p. ej. números tardíos).
        for (final j in eq.jugadores) {
          final lj = le.jugadores.where((e) => e.id == j.id).toList();
          if (lj.isEmpty) {
            le.jugadores.add(j);
          } else {
            lj.first.nombre = j.nombre;
            lj.first.apellido = j.apellido;
            lj.first.fechaNacimiento = j.fechaNacimiento;
            lj.first.telefono = j.telefono;
            lj.first.numero ??= j.numero;
            if (j.numero != null) lj.first.numero = j.numero;
            lj.first.fotoPath ??= j.fotoPath;
          }
        }
      }
    }
    for (final m in remoto.fixture) {
      if (!local.fixture.any((e) => e.id == m.id)) {
        local.fixture.add(m);
      }
    }
    for (final b in remoto.bajas) {
      if (!local.bajas.contains(b)) local.bajas.add(b);
    }
    for (final r in remoto.resultados) {
      final idx =
          local.resultados.indexWhere((e) => e.matchId == r.matchId);
      if (idx < 0) {
        local.resultados.add(r);
        resultadosNuevos++;
        try {
          final match =
              local.fixture.firstWhere((e) => e.id == r.matchId);
          match.jugado = true;
          match.programado = false;
        } catch (_) {}
      } else if (r.fecha.compareTo(local.resultados[idx].fecha) > 0) {
        local.resultados[idx] = r;
        resultadosNuevos++;
      }
    }
    final nuevos = avanzarDirecta(local);
    // Solo agrega rondas que no existan.
    for (final n in nuevos) {
      if (!local.fixture.any((e) => e.id == n.id)) {
        local.fixture.add(n);
      }
    }
    notifyListeners();
    return {'equipos': equiposNuevos, 'resultados': resultadosNuevos};
  }

  /// Descarga los torneos del equipo central y los fusiona aquí.
  Future<String> descargarDe(String base) async {
    final url = '${_base(base)}/api/torneos';
    final data = await _getJson(url);
    final lista = (data['torneos'] ?? []) as List;
    var t = 0, e = 0, r = 0;
    for (final raw in lista) {
      final remoto =
          Tournament.fromJson(Map<String, dynamic>.from(raw));
      final c = fusionarTorneo(remoto);
      t++;
      e += c['equipos']!;
      r += c['resultados']!;
    }
    await persistir();
    return 'Descargados $t torneos ($e equipos, $r resultados nuevos)';
  }

  /// Envía mis torneos al equipo central para fusionarlos allá.
  Future<String> sincronizar() async {
    if (serverUrl.isEmpty) return 'Sin central configurada';
    final url = '$serverUrl/api/sync';
    final data = await _postJson(url, {
      'torneos': torneos.map((e) => e.toJson()).toList(),
    });
    if (data['ok'] == true) {
      return 'Sincronizado: ${data['resultadosNuevos'] ?? 0} resultados nuevos en la central';
    }
    return 'La central respondió con error';
  }

  String _base(String b) => b.trim().replaceAll(RegExp(r'/+$'), '');

  Future<Map<String, dynamic>> _getJson(String url) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.getUrl(Uri.parse(url));
      final res = await req.close().timeout(const Duration(seconds: 15));
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) {
        throw 'HTTP ${res.statusCode}';
      }
      return Map<String, dynamic>.from(jsonDecode(body));
    } finally {
      client.close();
    }
  }

  Future<Map<String, dynamic>> _postJson(
      String url, Map<String, dynamic> payload) async {
    final client = HttpClient();
    client.connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.postUrl(Uri.parse(url));
      req.headers.contentType = ContentType.json;
      req.write(jsonEncode(payload));
      final res = await req.close().timeout(const Duration(seconds: 20));
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) {
        throw 'HTTP ${res.statusCode}: $body';
      }
      return Map<String, dynamic>.from(jsonDecode(body));
    } finally {
      client.close();
    }
  }

  PausaPartido? pausaDe(String torneoId, String matchId) =>
      pausas[_pausaKey(torneoId, matchId)];

  Future<void> guardarPausa(PausaPartido pausa) async {
    pausas[_pausaKey(pausa.torneoId, pausa.matchId)] = pausa;
    await persistir();
  }

  Future<void> borrarPausa(String torneoId, String matchId) async {
    pausas.remove(_pausaKey(torneoId, matchId));
    await persistir();
  }

  /// Da de baja a un equipo: todos sus partidos (jugados o no) se
  /// registran como derrota por default para los rivales con el
  /// formato de sets del torneo a 25-0 por set.
  Future<void> darDeBajaEquipo(Tournament t, String equipoId) async {
    final setsGanar = setsParaGanar(t.formato);
    final parcialesDefault =
        List<String>.generate(setsGanar, (_) => '25-0');
    if (!t.bajas.contains(equipoId)) t.bajas.add(equipoId);
    for (final m in t.fixture) {
      if (m.equipoAId != equipoId && m.equipoBId != equipoId) continue;
      final rivalId =
          m.equipoAId == equipoId ? m.equipoBId : m.equipoAId;
      final esA = m.equipoAId == rivalId;
      final setsA = esA ? setsGanar : 0;
      final setsB = esA ? 0 : setsGanar;
      // parciales orientados al fixture (equipoA-equipoB)
      final parc = parcialesDefault.map((p) {
        final partes = p.split('-');
        return esA ? p : '${partes[1]}-${partes[0]}';
      }).toList();
      t.resultados.removeWhere((e) => e.matchId == m.id);
      t.resultados.add(MatchResult(
        matchId: m.id,
        equipoAId: m.equipoAId,
        equipoBId: m.equipoBId,
        setsA: setsA,
        setsB: setsB,
        parciales: parc,
        ganadorId: rivalId,
        lugar: m.lugar,
        fecha: m.fecha.isEmpty
            ? DateTime.now().toIso8601String()
            : m.fecha,
      ));
      m.jugado = true;
      m.programado = false;
      pausas.remove(_pausaKey(t.id, m.id));
    }
    final nuevos = avanzarDirecta(t);
    t.fixture.addAll(nuevos);
    await persistir();
  }

  List<StatRow> estadisticas(Tournament t) {
    final map = {for (final e in t.equipos) e.id: StatRow(e.id)};
    for (final r in t.resultados) {
      final a = map[r.equipoAId];
      final b = map[r.equipoBId];
      if (a == null || b == null) continue;
      a.pj++;
      b.pj++;
      if (r.ganadorId == r.equipoAId) {
        a.pg++;
        b.pp++;
      } else {
        b.pg++;
        a.pp++;
      }
      a.sf += r.setsA;
      a.sc += r.setsB;
      b.sf += r.setsB;
      b.sc += r.setsA;
      for (final p in r.parciales) {
        final partes = p.split('-');
        if (partes.length != 2) continue;
        final pa = int.tryParse(partes[0].trim()) ?? 0;
        final pb = int.tryParse(partes[1].trim()) ?? 0;
        // parciales se guardan como A-B del partido (equipoA-equipoB)
        a.pf += pa;
        a.pc += pb;
        b.pf += pb;
        b.pc += pa;
      }
    }
    return map.values.toList();
  }

  List<StatRow> posiciones(Tournament t) {
    final l = estadisticas(t);
    l.sort((x, y) {
      var c = y.pg.compareTo(x.pg);
      if (c != 0) return c;
      c = y.difSets.compareTo(x.difSets);
      if (c != 0) return c;
      c = y.difPuntos.compareTo(x.difPuntos);
      if (c != 0) return c;
      return y.pf.compareTo(x.pf);
    });
    return l;
  }
}
