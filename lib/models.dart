import 'package:uuid/uuid.dart';

const _uuid = Uuid();

String newId() => _uuid.v4();

enum Formato { dosDeTres, tresDeCinco }
enum Sistema { roundRobin1, roundRobin2, eliminacionDirecta }

String formatoLabel(Formato f) =>
    f == Formato.dosDeTres ? 'Ganar 2 de 3 sets' : 'Ganar 3 de 5 sets';
String sistemaLabel(Sistema s) {
  switch (s) {
    case Sistema.roundRobin1:
      return 'Round Robin 1 vuelta';
    case Sistema.roundRobin2:
      return 'Round Robin 2 vueltas';
    case Sistema.eliminacionDirecta:
      return 'Eliminación directa';
  }
}

int setsParaGanar(Formato f) => f == Formato.dosDeTres ? 2 : 3;
int totalSets(Formato f) => f == Formato.dosDeTres ? 3 : 5;
bool esSetDefinitivo(int setNum, Formato f) => setNum == totalSets(f);
int puntosParaSet(int setNum, Formato f) =>
    esSetDefinitivo(setNum, f) ? 15 : 25;

class Player {
  String id;
  String nombre;
  String apellido;
  String fechaNacimiento;
  String telefono;
  String? fotoPath;
  int? numero;

  Player({
    String? id,
    required this.nombre,
    this.apellido = '',
    this.fechaNacimiento = '',
    this.telefono = '',
    this.fotoPath,
    this.numero,
  }) : id = id ?? newId();

  String get nombreCompleto =>
      '$nombre ${apellido.trim()}'.trim();

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'apellido': apellido,
        'fechaNacimiento': fechaNacimiento,
        'telefono': telefono,
        'fotoPath': fotoPath,
        'numero': numero,
      };
  factory Player.fromJson(Map<String, dynamic> j) => Player(
        id: j['id'] as String?,
        nombre: (j['nombre'] ?? '') as String,
        apellido: (j['apellido'] ?? '') as String,
        fechaNacimiento: (j['fechaNacimiento'] ?? '') as String,
        telefono: (j['telefono'] ?? '') as String,
        fotoPath: j['fotoPath'] as String?,
        numero: (j['numero'] as num?)?.toInt(),
      );
}

class Team {
  String id;
  String nombre;
  List<Player> jugadores;

  Team({String? id, required this.nombre, List<Player>? jugadores})
      : id = id ?? newId(),
        jugadores = jugadores ?? [];

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'jugadores': jugadores.map((e) => e.toJson()).toList(),
      };
  factory Team.fromJson(Map<String, dynamic> j) => Team(
        id: j['id'] as String?,
        nombre: (j['nombre'] ?? '') as String,
        jugadores: ((j['jugadores'] ?? []) as List)
            .map((e) => Player.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
      );
}

class Match {
  String id;
  String equipoAId;
  String equipoBId;
  int vuelta; // 1/2 para RR, ronda para directa (1=primera)
  String etiqueta;
  bool programado;
  bool jugado;
  String fecha;
  String lugar;

  Match({
    String? id,
    required this.equipoAId,
    required this.equipoBId,
    this.vuelta = 1,
    this.etiqueta = '',
    this.programado = false,
    this.jugado = false,
    this.fecha = '',
    this.lugar = '',
  }) : id = id ?? newId();

  Map<String, dynamic> toJson() => {
        'id': id,
        'equipoAId': equipoAId,
        'equipoBId': equipoBId,
        'vuelta': vuelta,
        'etiqueta': etiqueta,
        'programado': programado,
        'jugado': jugado,
        'fecha': fecha,
        'lugar': lugar,
      };
  factory Match.fromJson(Map<String, dynamic> j) => Match(
        id: j['id'] as String?,
        equipoAId: j['equipoAId'] as String,
        equipoBId: j['equipoBId'] as String,
        vuelta: (j['vuelta'] ?? 1) as int,
        etiqueta: (j['etiqueta'] ?? '') as String,
        programado: (j['programado'] ?? false) as bool,
        jugado: (j['jugado'] ?? false) as bool,
        fecha: (j['fecha'] ?? '') as String,
        lugar: (j['lugar'] ?? '') as String,
      );
}

class Sanction {
  String id;
  String tipo;
  String equipoId;
  String? jugadorNombre;
  int? jugadorNumero;
  bool grupal;
  int set;
  int marcadorA;
  int marcadorB;

  Sanction({
    String? id,
    required this.tipo,
    required this.equipoId,
    this.jugadorNombre,
    this.jugadorNumero,
    this.grupal = false,
    required this.set,
    required this.marcadorA,
    required this.marcadorB,
  }) : id = id ?? newId();

  Map<String, dynamic> toJson() => {
        'id': id,
        'tipo': tipo,
        'equipoId': equipoId,
        'jugadorNombre': jugadorNombre,
        'jugadorNumero': jugadorNumero,
        'grupal': grupal,
        'set': set,
        'marcadorA': marcadorA,
        'marcadorB': marcadorB,
      };
  factory Sanction.fromJson(Map<String, dynamic> j) => Sanction(
        id: j['id'] as String?,
        tipo: j['tipo'] as String,
        equipoId: j['equipoId'] as String,
        jugadorNombre: j['jugadorNombre'] as String?,
        jugadorNumero: (j['jugadorNumero'] as num?)?.toInt(),
        grupal: (j['grupal'] ?? false) as bool,
        set: (j['set'] ?? 1) as int,
        marcadorA: (j['marcadorA'] ?? 0) as int,
        marcadorB: (j['marcadorB'] ?? 0) as int,
      );
}

class PlayerSnapshot {
  String nombre;
  int? numero;
  PlayerSnapshot({required this.nombre, this.numero});
  Map<String, dynamic> toJson() => {'nombre': nombre, 'numero': numero};
  factory PlayerSnapshot.fromJson(Map<String, dynamic> j) =>
      PlayerSnapshot(
          nombre: j['nombre'] as String,
          numero: (j['numero'] as num?)?.toInt());
}

class MatchResult {
  String matchId;
  String equipoAId;
  String equipoBId;
  int setsA;
  int setsB;
  List<String> parciales;
  String ganadorId;
  List<Sanction> sanciones;
  List<PlayerSnapshot> jugadoresA;
  List<PlayerSnapshot> jugadoresB;
  String fecha;
  String lugar;
  List<int> tiemposA;
  List<int> tiemposB;
  List<int> cambiosA;
  List<int> cambiosB;

  MatchResult({
    required this.matchId,
    required this.equipoAId,
    required this.equipoBId,
    required this.setsA,
    required this.setsB,
    required this.parciales,
    required this.ganadorId,
    List<Sanction>? sanciones,
    List<PlayerSnapshot>? jugadoresA,
    List<PlayerSnapshot>? jugadoresB,
    String? fecha,
    this.lugar = '',
    List<int>? tiemposA,
    List<int>? tiemposB,
    List<int>? cambiosA,
    List<int>? cambiosB,
  })  : sanciones = sanciones ?? [],
        jugadoresA = jugadoresA ?? [],
        jugadoresB = jugadoresB ?? [],
        fecha = fecha ?? DateTime.now().toIso8601String(),
        tiemposA = tiemposA ?? [],
        tiemposB = tiemposB ?? [],
        cambiosA = cambiosA ?? [],
        cambiosB = cambiosB ?? [];

  int get totalTiemposA => tiemposA.fold(0, (a, b) => a + b);
  int get totalTiemposB => tiemposB.fold(0, (a, b) => a + b);
  int get totalCambiosA => cambiosA.fold(0, (a, b) => a + b);
  int get totalCambiosB => cambiosB.fold(0, (a, b) => a + b);

  Map<String, dynamic> toJson() => {
        'matchId': matchId,
        'equipoAId': equipoAId,
        'equipoBId': equipoBId,
        'setsA': setsA,
        'setsB': setsB,
        'parciales': parciales,
        'ganadorId': ganadorId,
        'sanciones': sanciones.map((e) => e.toJson()).toList(),
        'jugadoresA': jugadoresA.map((e) => e.toJson()).toList(),
        'jugadoresB': jugadoresB.map((e) => e.toJson()).toList(),
        'fecha': fecha,
        'lugar': lugar,
        'tiemposA': tiemposA,
        'tiemposB': tiemposB,
        'cambiosA': cambiosA,
        'cambiosB': cambiosB,
      };
  factory MatchResult.fromJson(Map<String, dynamic> j) => MatchResult(
        matchId: j['matchId'] as String,
        equipoAId: j['equipoAId'] as String,
        equipoBId: j['equipoBId'] as String,
        setsA: (j['setsA'] ?? 0) as int,
        setsB: (j['setsB'] ?? 0) as int,
        parciales: ((j['parciales'] ?? []) as List).map((e) => '$e').toList(),
        ganadorId: j['ganadorId'] as String,
        sanciones: ((j['sanciones'] ?? []) as List)
            .map((e) => Sanction.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        jugadoresA: ((j['jugadoresA'] ?? []) as List)
            .map((e) => PlayerSnapshot.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        jugadoresB: ((j['jugadoresB'] ?? []) as List)
            .map((e) => PlayerSnapshot.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        fecha: j['fecha'] as String?,
        lugar: (j['lugar'] ?? '') as String,
        tiemposA: ((j['tiemposA'] ?? []) as List)
            .map((e) => (e as num).toInt())
            .toList(),
        tiemposB: ((j['tiemposB'] ?? []) as List)
            .map((e) => (e as num).toInt())
            .toList(),
        cambiosA: ((j['cambiosA'] ?? []) as List)
            .map((e) => (e as num).toInt())
            .toList(),
        cambiosB: ((j['cambiosB'] ?? []) as List)
            .map((e) => (e as num).toInt())
            .toList(),
      );
}

/// Estado de un encuentro suspendido a mitad (para "Continuar encuentro").
class PausaPartido {
  String torneoId;
  String matchId;
  String ladoAId;
  String ladoBId;
  String sacaId;
  int setNumero;
  int pA;
  int pB;
  int tA;
  int tB;
  List<String> posA;
  List<String> posB;
  Map<String, dynamic> subA;
  Map<String, dynamic> subB;
  bool ladoInvertido;
  bool cambioHecho;
  int accSetsFA;
  int accSetsFB;
  List<String> accParciales;
  List<Map<String, dynamic>> accSanciones;
  List<String> accJugA;
  List<String> accJugB;
  List<int> accTiemposA;
  List<int> accTiemposB;
  List<int> accCambiosA;
  List<int> accCambiosB;
  String ladoAOrig;
  String ladoBOrig;
  String saqueOrig;
  List<String> titA;
  List<String> titB;

  PausaPartido({
    required this.torneoId,
    required this.matchId,
    required this.ladoAId,
    required this.ladoBId,
    required this.sacaId,
    required this.setNumero,
    required this.pA,
    required this.pB,
    required this.tA,
    required this.tB,
    required this.posA,
    required this.posB,
    required this.subA,
    required this.subB,
    required this.ladoInvertido,
    required this.cambioHecho,
    required this.accSetsFA,
    required this.accSetsFB,
    required this.accParciales,
    required this.accSanciones,
    required this.accJugA,
    required this.accJugB,
    required this.accTiemposA,
    required this.accTiemposB,
    required this.accCambiosA,
    required this.accCambiosB,
    required this.ladoAOrig,
    required this.ladoBOrig,
    required this.saqueOrig,
    List<String>? titA,
    List<String>? titB,
  })  : titA = titA ?? [],
        titB = titB ?? [];

  Map<String, dynamic> toJson() => {
        'torneoId': torneoId,
        'matchId': matchId,
        'ladoAId': ladoAId,
        'ladoBId': ladoBId,
        'sacaId': sacaId,
        'setNumero': setNumero,
        'pA': pA,
        'pB': pB,
        'tA': tA,
        'tB': tB,
        'posA': posA,
        'posB': posB,
        'subA': subA,
        'subB': subB,
        'ladoInvertido': ladoInvertido,
        'cambioHecho': cambioHecho,
        'accSetsFA': accSetsFA,
        'accSetsFB': accSetsFB,
        'accParciales': accParciales,
        'accSanciones': accSanciones,
        'accJugA': accJugA,
        'accJugB': accJugB,
        'accTiemposA': accTiemposA,
        'accTiemposB': accTiemposB,
        'accCambiosA': accCambiosA,
        'accCambiosB': accCambiosB,
        'ladoAOrig': ladoAOrig,
        'ladoBOrig': ladoBOrig,
        'saqueOrig': saqueOrig,
        'titA': titA,
        'titB': titB,
      };
  factory PausaPartido.fromJson(Map<String, dynamic> j) => PausaPartido(
        torneoId: j['torneoId'] as String,
        matchId: j['matchId'] as String,
        ladoAId: j['ladoAId'] as String,
        ladoBId: j['ladoBId'] as String,
        sacaId: j['sacaId'] as String,
        setNumero: (j['setNumero'] ?? 1) as int,
        pA: (j['pA'] ?? 0) as int,
        pB: (j['pB'] ?? 0) as int,
        tA: (j['tA'] ?? 0) as int,
        tB: (j['tB'] ?? 0) as int,
        posA: ((j['posA'] ?? []) as List).map((e) => '$e').toList(),
        posB: ((j['posB'] ?? []) as List).map((e) => '$e').toList(),
        subA: Map<String, dynamic>.from(j['subA'] ?? {}),
        subB: Map<String, dynamic>.from(j['subB'] ?? {}),
        ladoInvertido: (j['ladoInvertido'] ?? false) as bool,
        cambioHecho: (j['cambioHecho'] ?? false) as bool,
        accSetsFA: (j['accSetsFA'] ?? 0) as int,
        accSetsFB: (j['accSetsFB'] ?? 0) as int,
        accParciales:
            ((j['accParciales'] ?? []) as List).map((e) => '$e').toList(),
        accSanciones: ((j['accSanciones'] ?? []) as List)
            .map((e) => Map<String, dynamic>.from(e))
            .toList(),
        accJugA: ((j['accJugA'] ?? []) as List).map((e) => '$e').toList(),
        accJugB: ((j['accJugB'] ?? []) as List).map((e) => '$e').toList(),
        accTiemposA: ((j['accTiemposA'] ?? []) as List)
            .map((e) => (e as num).toInt())
            .toList(),
        accTiemposB: ((j['accTiemposB'] ?? []) as List)
            .map((e) => (e as num).toInt())
            .toList(),
        accCambiosA: ((j['accCambiosA'] ?? []) as List)
            .map((e) => (e as num).toInt())
            .toList(),
        accCambiosB: ((j['accCambiosB'] ?? []) as List)
            .map((e) => (e as num).toInt())
            .toList(),
        ladoAOrig: (j['ladoAOrig'] ?? j['ladoAId']) as String,
        ladoBOrig: (j['ladoBOrig'] ?? j['ladoBId']) as String,
        saqueOrig: (j['saqueOrig'] ?? j['sacaId']) as String,
        titA: ((j['titA'] ?? j['posA'] ?? []) as List)
            .map((e) => '$e')
            .toList(),
        titB: ((j['titB'] ?? j['posB'] ?? []) as List)
            .map((e) => '$e')
            .toList(),
      );
}

class Tournament {
  String id;
  String nombre;
  Formato formato;
  Sistema sistema;
  List<Team> equipos;
  List<Match> fixture;
  List<MatchResult> resultados;
  String creado;
  List<String> bajas;

  Tournament({
    String? id,
    required this.nombre,
    required this.formato,
    required this.sistema,
    List<Team>? equipos,
    List<Match>? fixture,
    List<MatchResult>? resultados,
    String? creado,
    List<String>? bajas,
  })  : id = id ?? newId(),
        equipos = equipos ?? [],
        fixture = fixture ?? [],
        resultados = resultados ?? [],
        creado = creado ?? DateTime.now().toIso8601String(),
        bajas = bajas ?? [];

  bool estaDeBaja(String equipoId) => bajas.contains(equipoId);

  String nombreEquipo(String id) {
    final t = equipos.where((e) => e.id == id).toList();
    if (t.isEmpty) return 'Equipo';
    return t.first.nombre;
  }

  Team? equipoPorId(String id) {
    try {
      return equipos.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nombre': nombre,
        'formato': formato.index,
        'sistema': sistema.index,
        'equipos': equipos.map((e) => e.toJson()).toList(),
        'fixture': fixture.map((e) => e.toJson()).toList(),
        'resultados': resultados.map((e) => e.toJson()).toList(),
        'creado': creado,
        'bajas': bajas,
      };
  factory Tournament.fromJson(Map<String, dynamic> j) => Tournament(
        id: j['id'] as String?,
        nombre: (j['nombre'] ?? '') as String,
        formato: Formato.values[(j['formato'] ?? 0) as int],
        sistema: Sistema.values[(j['sistema'] ?? 0) as int],
        equipos: ((j['equipos'] ?? []) as List)
            .map((e) => Team.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        fixture: ((j['fixture'] ?? []) as List)
            .map((e) => Match.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        resultados: ((j['resultados'] ?? []) as List)
            .map((e) => MatchResult.fromJson(Map<String, dynamic>.from(e)))
            .toList(),
        creado: j['creado'] as String?,
        bajas:
            ((j['bajas'] ?? []) as List).map((e) => '$e').toList(),
      );
}

const tiposSancion = [
  'Amonestación',
  'Castigo',
  'Expulsión',
  'Descalificación',
  'Amonestación por demora',
  'Castigo por demora',
];
