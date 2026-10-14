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

  Match({
    String? id,
    required this.equipoAId,
    required this.equipoBId,
    this.vuelta = 1,
    this.etiqueta = '',
    this.programado = false,
    this.jugado = false,
  }) : id = id ?? newId();

  Map<String, dynamic> toJson() => {
        'id': id,
        'equipoAId': equipoAId,
        'equipoBId': equipoBId,
        'vuelta': vuelta,
        'etiqueta': etiqueta,
        'programado': programado,
        'jugado': jugado,
      };
  factory Match.fromJson(Map<String, dynamic> j) => Match(
        id: j['id'] as String?,
        equipoAId: j['equipoAId'] as String,
        equipoBId: j['equipoBId'] as String,
        vuelta: (j['vuelta'] ?? 1) as int,
        etiqueta: (j['etiqueta'] ?? '') as String,
        programado: (j['programado'] ?? false) as bool,
        jugado: (j['jugado'] ?? false) as bool,
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
  })  : sanciones = sanciones ?? [],
        jugadoresA = jugadoresA ?? [],
        jugadoresB = jugadoresB ?? [],
        fecha = fecha ?? DateTime.now().toIso8601String();

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

  Tournament({
    String? id,
    required this.nombre,
    required this.formato,
    required this.sistema,
    List<Team>? equipos,
    List<Match>? fixture,
    List<MatchResult>? resultados,
    String? creado,
  })  : id = id ?? newId(),
        equipos = equipos ?? [],
        fixture = fixture ?? [],
        resultados = resultados ?? [],
        creado = creado ?? DateTime.now().toIso8601String();

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
