import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../store.dart';
import '../rules.dart';
import 'side_serve_screen.dart';
import 'lineup_screen.dart';
import 'jornada_screen.dart';

class _Acc {
  int setsFA = 0;
  int setsFB = 0;
  List<String> parciales = [];
  List<Sanction> sanciones = [];
  Set<String> jugA = {};
  Set<String> jugB = {};
  // Tiempos/cambios por set en orden fixture (A/B del fixture)
  List<int> tiemposFA = [];
  List<int> tiemposFB = [];
  List<int> cambiosFA = [];
  List<int> cambiosFB = [];
}

class LiveGameScreen extends StatefulWidget {
  final String torneoId;
  final String matchId;
  final String ladoAId;
  final String ladoBId;
  final String saqueId;
  final int setNumero;
  final List<String> lineupA; // ids pos1..6 ladoA
  final List<String> lineupB; // ids pos1..6 ladoB
  final List<String>? prevA;
  final List<String>? prevB;
  final PausaPartido? pausaInicial;
  /// true cuando se reanuda con alineación editada: el marcador y los
  /// sets se conservan pero los cambios se reinician desde [lineupA/B].
  final bool reanudaConNuevaAlineacion;
  const LiveGameScreen(
      {super.key,
      required this.torneoId,
      required this.matchId,
      required this.ladoAId,
      required this.ladoBId,
      required this.saqueId,
      required this.setNumero,
      required this.lineupA,
      required this.lineupB,
      this.prevA,
      this.prevB,
      this.pausaInicial,
      this.reanudaConNuevaAlineacion = false});

  factory LiveGameScreen.desdePausa({required PausaPartido pausa}) =>
      LiveGameScreen(
        torneoId: pausa.torneoId,
        matchId: pausa.matchId,
        ladoAId: pausa.ladoAId,
        ladoBId: pausa.ladoBId,
        saqueId: pausa.sacaId,
        setNumero: pausa.setNumero,
        lineupA: List<String>.from(pausa.posA),
        lineupB: List<String>.from(pausa.posB),
        pausaInicial: pausa,
      );

  /// Reanuda con alineación editada para lo que resta del set.
  factory LiveGameScreen.reanudar(
          {required PausaPartido pausa,
          required List<String> lineupA,
          required List<String> lineupB}) =>
      LiveGameScreen(
        torneoId: pausa.torneoId,
        matchId: pausa.matchId,
        ladoAId: pausa.ladoAId,
        ladoBId: pausa.ladoBId,
        saqueId: pausa.sacaId,
        setNumero: pausa.setNumero,
        lineupA: lineupA,
        lineupB: lineupB,
        pausaInicial: pausa,
        reanudaConNuevaAlineacion: true,
      );

  static final Map<String, _Acc> sesiones = {};

  @override
  State<LiveGameScreen> createState() => _State();
}

class _State extends State<LiveGameScreen> {
  late List<String> posA; // idx0=pos1
  late List<String> posB;
  late String saca; // teamId con saque
  int pA = 0, pB = 0;
  int tA = 0, tB = 0; // tiempos usados en el set
  late ControlSustituciones subA, subB;
  late Set<String> titA, titB;
  bool ladoInvertido = false;
  bool cambioDefinitivoHecho = false;
  bool setTerminado = false;

  _Acc get acc => LiveGameScreen.sesiones.putIfAbsent(
      '${widget.torneoId}_${widget.matchId}', () => _Acc());

  String get _key => '${widget.torneoId}_${widget.matchId}';

  @override
  void initState() {
    super.initState();
    final pausa = widget.pausaInicial;
    if (pausa != null) {
      // (4) Restaurar encuentro suspendido tal cual se quedó.
      final nuevaAlineacion = widget.reanudaConNuevaAlineacion;
      posA = nuevaAlineacion
          ? List<String>.from(widget.lineupA)
          : List<String>.from(pausa.posA);
      posB = nuevaAlineacion
          ? List<String>.from(widget.lineupB)
          : List<String>.from(pausa.posB);
      saca = pausa.sacaId;
      pA = pausa.pA;
      pB = pausa.pB;
      tA = pausa.tA;
      tB = pausa.tB;
      if (nuevaAlineacion) {
        // Los cambios comienzan desde la nueva alineación.
        subA = ControlSustituciones();
        subB = ControlSustituciones();
        titA = posA.toSet();
        titB = posB.toSet();
      } else {
        subA = ControlSustituciones.desdeJson(pausa.subA);
        subB = ControlSustituciones.desdeJson(pausa.subB);
        titA = pausa.titA.toSet();
        if (titA.isEmpty) titA = posA.toSet();
        titB = pausa.titB.toSet();
        if (titB.isEmpty) titB = posB.toSet();
      }
      ladoInvertido = pausa.ladoInvertido;
      cambioDefinitivoHecho = pausa.cambioHecho;
      final a = _Acc()
        ..setsFA = pausa.accSetsFA
        ..setsFB = pausa.accSetsFB
        ..parciales = List<String>.from(pausa.accParciales)
        ..sanciones = pausa.accSanciones
            .map((e) => Sanction.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        ..jugA = pausa.accJugA.toSet()
        ..jugB = pausa.accJugB.toSet()
        ..tiemposFA = List<int>.from(pausa.accTiemposA)
        ..tiemposFB = List<int>.from(pausa.accTiemposB)
        ..cambiosFA = List<int>.from(pausa.accCambiosA)
        ..cambiosFB = List<int>.from(pausa.accCambiosB);
      LiveGameScreen.sesiones[_key] = a;
      if (nuevaAlineacion) {
        // Registrar a las jugadoras nuevas en el acumulado del partido.
        final fixA = _fixture().equipoAId;
        for (final id in [...posA, ..._bancaIds(true)]) {
          if (fixA == widget.ladoAId) {
            a.jugA.add(id);
          } else {
            a.jugB.add(id);
          }
        }
        for (final id in [...posB, ..._bancaIds(false)]) {
          if (fixA == widget.ladoBId) {
            a.jugA.add(id);
          } else {
            a.jugB.add(id);
          }
        }
      }
      return;
    }
    posA = List<String>.from(widget.lineupA);
    posB = List<String>.from(widget.lineupB);
    saca = widget.saqueId;
    subA = ControlSustituciones();
    subB = ControlSustituciones();
    titA = posA.toSet();
    titB = posB.toSet();
    if (widget.setNumero == 1) {
      // Inicio desde cero (roster): descarta acumulados/pausa viejos
      // del mismo partido para no arrastrar otro encuentro.
      LiveGameScreen.sesiones[_key] = _Acc();
      context.read<AppStore>().borrarPausa(widget.torneoId, widget.matchId);
    }
    // registrar jugadores que participan
    final fixA = _fixture().equipoAId;
    for (final id in [...posA, ..._bancaIds(true)]) {
      if (fixA == widget.ladoAId) {
        acc.jugA.add(id);
      } else {
        acc.jugB.add(id);
      }
    }
    for (final id in [...posB, ..._bancaIds(false)]) {
      if (fixA == widget.ladoBId) {
        acc.jugA.add(id);
      } else {
        acc.jugB.add(id);
      }
    }
  }

  Tournament _torneo() =>
      context.read<AppStore>().porId(widget.torneoId)!;
  Match _fixture() => _torneo()
      .fixture
      .firstWhere((e) => e.id == widget.matchId);

  Team _team(String id) => _torneo().equipoPorId(id)!;
  String _nombre(String id) => _torneo().nombreEquipo(id);
  String _nombreJug(String id) {
    for (final eq in _torneo().equipos) {
      for (final j in eq.jugadores) {
        if (j.id == id) {
          return '#${j.numero ?? '-'} ${j.nombreCompleto}';
        }
      }
    }
    return id.length > 4 ? id.substring(0, 4) : id;
  }

  int? _numeroJug(String id) {
    for (final eq in _torneo().equipos) {
      for (final j in eq.jugadores) {
        if (j.id == id) return j.numero;
      }
    }
    return null;
  }

  List<String> _bancaIds(bool esA) {
    final eq = _team(esA ? widget.ladoAId : widget.ladoBId);
    final activos = (esA ? posA : posB).toSet();
    return eq.jugadores
        .where((j) => j.numero != null && !activos.contains(j.id))
        .map((j) => j.id)
        .toList();
  }

  void _punto(bool paraA, {bool resta = false}) {
    if (setTerminado) return;
    setState(() {
      if (!resta) {
        final ganadorId = paraA ? widget.ladoAId : widget.ladoBId;
        if (ganadorId != saca) {
          if (paraA) {
            posA = rotar(posA);
          } else {
            posB = rotar(posB);
          }
          saca = ganadorId;
        }
        if (paraA) {
          pA++;
        } else {
          pB++;
        }
      } else {
        if (paraA && pA > 0) pA--;
        if (!paraA && pB > 0) pB--;
      }
      // (10) Definitivo: cambio cuando UN equipo llega a 8 (no suma 8).
      // El punto anterior cuenta: si se resta después, no se revierte.
      final f = _torneo().formato;
      if (esSetDefinitivo(widget.setNumero, f) &&
          !cambioDefinitivoHecho &&
          (pA == 8 || pB == 8)) {
        cambioDefinitivoHecho = true;
        ladoInvertido = !ladoInvertido;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Set definitivo: un equipo llegó a 8, cambio de lado automático')));
      }
      _verificarFinSet();
    });
  }

  void _registrarSetEnAcc(bool ganoA) {
    final fix = _fixture();
    String parcial;
    if (fix.equipoAId == widget.ladoAId) {
      parcial = '$pA-$pB';
    } else {
      parcial = '$pB-$pA';
    }
    acc.parciales.add(parcial);
    final ladoAGano = ganoA;
    if ((fix.equipoAId == widget.ladoAId && ladoAGano) ||
        (fix.equipoBId == widget.ladoAId && ladoAGano)) {
      if (fix.equipoAId == widget.ladoAId) {
        acc.setsFA++;
      } else {
        acc.setsFB++;
      }
    } else {
      if (fix.equipoAId == widget.ladoBId) {
        acc.setsFA++;
      } else {
        acc.setsFB++;
      }
    }
    // Tiempos/cambios del set en orden fixture
    if (fix.equipoAId == widget.ladoAId) {
      acc.tiemposFA.add(tA);
      acc.tiemposFB.add(tB);
      acc.cambiosFA.add(subA.usadas);
      acc.cambiosFB.add(subB.usadas);
    } else {
      acc.tiemposFA.add(tB);
      acc.tiemposFB.add(tA);
      acc.cambiosFA.add(subB.usadas);
      acc.cambiosFB.add(subA.usadas);
    }
    for (final id in posA) {
      if (fix.equipoAId == widget.ladoAId) {
        acc.jugA.add(id);
      } else {
        acc.jugB.add(id);
      }
    }
    for (final id in posB) {
      if (fix.equipoAId == widget.ladoBId) {
        acc.jugA.add(id);
      } else {
        acc.jugB.add(id);
      }
    }
    context.read<AppStore>().persistir();
  }

  void _verificarFinSet() {
    final f = _torneo().formato;
    if (!ganaSet(pA, pB, widget.setNumero, f)) return;
    setTerminado = true;
    final ganoA = pA > pB;
    _registrarSetEnAcc(ganoA);
    final need = setsParaGanar(f);
    final finPartido = acc.setsFA >= need || acc.setsFB >= need;
    if (finPartido) {
      _mostrarFinal();
    } else {
      final next = widget.setNumero + 1;
      final esDef = esSetDefinitivo(next, f);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
          title: Text('Set ${widget.setNumero} terminado $pA-$pB'),
          content: Text(esDef
              ? 'Vamos al set definitivo. Elige lado y saque.'
              : 'Continúa a la alineación del set $next.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                if (esDef) {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => SideServeScreen(
                              torneoId: widget.torneoId,
                              matchId: widget.matchId,
                              setNumero: next,
                              esDefinitivo: true)));
                } else {
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => LineupScreen(
                                torneoId: widget.torneoId,
                                matchId: widget.matchId,
                                ladoAId: widget.ladoAId,
                                ladoBId: widget.ladoBId,
                                saqueId: saca,
                                setNumero: next,
                              )));
                }
              },
              child: const Text('Continuar'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _mostrarFinal() async {
    final fix = _fixture();
    final t = _torneo();
    final ganadorId =
        acc.setsFA > acc.setsFB ? fix.equipoAId : fix.equipoBId;
    final setsA = acc.setsFA;
    final setsB = acc.setsFB;
    List<PlayerSnapshot> snap(Set<String> ids) {
      return ids.map((id) {
        String nom = id;
        int? num;
        for (final eq in t.equipos) {
          for (final j in eq.jugadores) {
            if (j.id == id) {
              nom = j.nombreCompleto;
              num = j.numero;
            }
          }
        }
        return PlayerSnapshot(nombre: nom, numero: num);
      }).toList();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Center(
            child: Text('🏆 ${_nombre(ganadorId)}',
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
                '${_nombre(fix.equipoAId)} $setsA - $setsB ${_nombre(fix.equipoBId)}'),
            Text('Sets: ${acc.parciales.join(' | ')}'),
            if (acc.sanciones.isNotEmpty)
              Text(
                  'Sanciones: ${acc.sanciones.length} registradas'),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () async {
              final store = context.read<AppStore>();
              final r = MatchResult(
                matchId: fix.id,
                equipoAId: fix.equipoAId,
                equipoBId: fix.equipoBId,
                setsA: setsA,
                setsB: setsB,
                parciales: List<String>.from(acc.parciales),
                ganadorId: ganadorId,
                sanciones: List<Sanction>.from(acc.sanciones),
                jugadoresA: snap(fix.equipoAId == widget.ladoAId
                    ? _todosLado(true)
                    : _todosLado(false)),
                jugadoresB: snap(fix.equipoAId == widget.ladoAId
                    ? _todosLado(false)
                    : _todosLado(true)),
                fecha: fix.fecha.isEmpty
                    ? DateTime.now().toIso8601String()
                    : fix.fecha,
                lugar: fix.lugar,
                tiemposA: List<int>.from(acc.tiemposFA),
                tiemposB: List<int>.from(acc.tiemposFB),
                cambiosA: List<int>.from(acc.cambiosFA),
                cambiosB: List<int>.from(acc.cambiosFB),
              );
              LiveGameScreen.sesiones.remove(_key);
              await store.guardarResultado(t, fix, r);
              if (!context.mounted) return;
              Navigator.popUntil(context, (ro) => ro.isFirst);
            },
            child: const Text('Guardar y salir'),
          ),
        ],
      ),
    );
  }

  Set<String> _todosLado(bool esLadoA) {
    final ids = <String>{};
    if (esLadoA) {
      ids.addAll(posA);
      ids.addAll(_bancaIds(true));
      final fix = _fixture();
      if (fix.equipoAId == widget.ladoAId) {
        ids.addAll(acc.jugA);
      } else {
        ids.addAll(acc.jugB);
      }
    } else {
      ids.addAll(posB);
      ids.addAll(_bancaIds(false));
      final fix = _fixture();
      if (fix.equipoAId == widget.ladoBId) {
        ids.addAll(acc.jugA);
      } else {
        ids.addAll(acc.jugB);
      }
    }
    return ids;
  }

  /// (4) Suspender: guarda el punto exacto en el sistema y vuelve
  /// directamente a la pantalla Jornada actual.
  Future<void> _suspender() async {
    final store = context.read<AppStore>();
    final fix = _fixture();
    final pausa = PausaPartido(
      torneoId: widget.torneoId,
      matchId: widget.matchId,
      ladoAId: widget.ladoAId,
      ladoBId: widget.ladoBId,
      sacaId: saca,
      setNumero: widget.setNumero,
      pA: pA,
      pB: pB,
      tA: tA,
      tB: tB,
      posA: List<String>.from(posA),
      posB: List<String>.from(posB),
      subA: subA.toJson(),
      subB: subB.toJson(),
      ladoInvertido: ladoInvertido,
      cambioHecho: cambioDefinitivoHecho,
      accSetsFA: acc.setsFA,
      accSetsFB: acc.setsFB,
      accParciales: List<String>.from(acc.parciales),
      accSanciones: acc.sanciones.map((e) => e.toJson()).toList(),
      accJugA: acc.jugA.toList(),
      accJugB: acc.jugB.toList(),
      accTiemposA: List<int>.from(acc.tiemposFA),
      accTiemposB: List<int>.from(acc.tiemposFB),
      accCambiosA: List<int>.from(acc.cambiosFA),
      accCambiosB: List<int>.from(acc.cambiosFB),
      ladoAOrig: widget.ladoAId,
      ladoBOrig: widget.ladoBId,
      saqueOrig: widget.saqueId,
      titA: titA.toList(),
      titB: titB.toList(),
    );
    // Guardado directo en el sistema (persistente).
    await store.guardarPausa(pausa);
    fix.programado = true;
    await store.persistir();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(
            'Partido guardado en set ${widget.setNumero} ($pA-$pB). Usa "Continuar encuentro" en Jornada actual.')));
    // Ir directo a Jornada actual, saliendo del flujo de pantallas.
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (_) => JornadaScreen(torneoId: widget.torneoId)),
        (r) => r.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final ladoA = widget.ladoAId;
    final ladoB = widget.ladoBId;
    final izqEsA = !ladoInvertido;
    final idIzq = izqEsA ? ladoA : ladoB;
    final idDer = izqEsA ? ladoB : ladoA;
    final pIzq = izqEsA ? pA : pB;
    final pDer = izqEsA ? pB : pA;
    final setsIzq = _setsDe(idIzq);
    final setsDer = _setsDe(idDer);

    return Scaffold(
      appBar: AppBar(
          title: Text(
              '${_nombre(ladoA)} vs ${_nombre(ladoB)} • Set ${widget.setNumero}'),
          actions: [
            IconButton(
              tooltip: 'Suspender encuentro',
              icon: const Icon(Icons.pause_circle),
              onPressed: _suspender,
            ),
          ]),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Text('${_nombre(idIzq)}  vs  ${_nombre(idDer)}',
              textAlign: TextAlign.center,
              style:
                  const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Text('Sets: $setsIzq - $setsDer',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _marcador(idIzq, pIzq)),
              const Padding(
                padding: EdgeInsets.only(top: 60),
                child: Text(':', style: TextStyle(fontSize: 60)),
              ),
              Expanded(child: _marcador(idDer, pDer)),
            ],
          ),
          const SizedBox(height: 8),
          _cancha(),
          const SizedBox(height: 8),
          _banca(),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                  child: ElevatedButton(
                      onPressed: () => _dialogoSancion(),
                      child: const Text('Sanciones'))),
              const SizedBox(width: 8),
              Expanded(
                  child: OutlinedButton(
                      onPressed: () =>
                          setState(() => ladoInvertido = !ladoInvertido),
                      child: const Text('Cambio de lado'))),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.pause),
            label: const Text(
                'Suspender encuentro (continuar después)'),
            onPressed: _suspender,
          ),
        ],
      ),
    );
  }

  int _setsDe(String teamId) {
    final fix = _fixture();
    if (teamId == fix.equipoAId) return acc.setsFA;
    return acc.setsFB;
  }

  /// (7) Marcador al doble (112) y números negros en negritas.
  Widget _marcador(String teamId, int pts) {
    final paraA = teamId == widget.ladoAId;
    final tiempos = paraA ? tA : tB;
    final cambios = paraA ? subA.usadas : subB.usadas;
    return Column(
      children: [
        Text(_nombre(teamId),
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.black, width: 2),
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text('$pts',
                style: const TextStyle(
                    fontSize: 112,
                    fontWeight: FontWeight.w900,
                    color: Colors.black)),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
                onPressed: () => _punto(paraA),
                child: const Text('+1',
                    style: TextStyle(fontSize: 20))),
            const SizedBox(width: 8),
            OutlinedButton(
                onPressed: () => _punto(paraA, resta: true),
                child: const Text('-1')),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _pedirTiempo(paraA),
              child: Text('Tiempo ($tiempos/2)'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _dialogoCambio(paraA),
              child: Text('Cambio ($cambios/6)'),
            ),
          ],
        ),
        if (saca == teamId)
          const Text('● SAQUE',
              style: TextStyle(
                  color: Colors.orange, fontWeight: FontWeight.bold)),
      ],
    );
  }

  void _pedirTiempo(bool paraA) {
    setState(() {
      if (paraA) {
        if (!puedePedirTiempo(tA)) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Máximo 2 tiempos por set (FIVB 30s c/u).')));
          return;
        }
        tA++;
      } else {
        if (!puedePedirTiempo(tB)) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text(
                  'Máximo 2 tiempos por set (FIVB 30s c/u).')));
          return;
        }
        tB++;
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Tiempo de 30s registrado (FIVB).')));
    });
  }

  /// Cancha naranja con líneas blancas, red negra y línea de ataque
  /// a 1/3 de la red hacia la zona zaguera (separa delanteros/zagueros).
  Widget _cancha() {
    Widget celda(String id, bool conSaque) {
      final num = _numeroJug(id)?.toString() ?? '?';
      return Container(
        width: 72,
        height: 72,
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: conSaque ? Colors.yellow : Colors.white,
          border: Border.all(color: Colors.black, width: 2),
          borderRadius: BorderRadius.circular(36),
        ),
        child: Center(
            child: Text(num,
                style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    color: Colors.black))),
      );
    }

    List<String> posDe(String teamId) =>
        teamId == widget.ladoAId ? posA : posB;
    String sacaDe(String teamId) =>
        saca == teamId ? posDe(teamId)[0] : '';

    Widget colAtras(String teamId, List<String> ids) {
      final s = sacaDe(teamId);
      return Column(
          children: ids.map((p) => celda(p, p == s)).toList());
    }

    Widget colDelante(String teamId, List<String> ids) {
      final s = sacaDe(teamId);
      return Column(
          children: ids.map((p) => celda(p, p == s)).toList());
    }

    // Línea blanca de ataque (3 m): separa delanteros de zagueros.
    Widget lineaAtaque() => Container(
        width: 4, height: 300, color: Colors.white);

    // Mitad izquierda: zaguero al doble de ancho que el ataque (2/3-1/3).
    Widget mitadIzq(String teamId) {
      final pos = posDe(teamId);
      return Container(
        decoration: BoxDecoration(
          color: Colors.orange.shade700,
          border: Border.all(color: Colors.white, width: 3),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Column(
          children: [
            Text(_nombre(teamId),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
            Row(children: [
              SizedBox(
                  width: 220,
                  child: Center(
                      child:
                          colAtras(teamId, [pos[4], pos[5], pos[0]]))),
              lineaAtaque(),
              SizedBox(
                  width: 110,
                  child: Center(
                      child:
                          colDelante(teamId, [pos[3], pos[2], pos[1]]))),
            ]),
          ],
        ),
      );
    }

    // Mitad derecha espejeada: ataque (1/3) |línea| zaguero (2/3).
    Widget mitadDer(String teamId) {
      final pos = posDe(teamId);
      return Container(
        decoration: BoxDecoration(
          color: Colors.orange.shade700,
          border: Border.all(color: Colors.white, width: 3),
        ),
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
        child: Column(
          children: [
            Text(_nombre(teamId),
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.white)),
            Row(children: [
              SizedBox(
                  width: 110,
                  child: Center(
                      child:
                          colDelante(teamId, [pos[1], pos[2], pos[3]]))),
              lineaAtaque(),
              SizedBox(
                  width: 220,
                  child: Center(
                      child:
                          colAtras(teamId, [pos[0], pos[5], pos[4]]))),
            ]),
          ],
        ),
      );
    }

    final izqEsA = !ladoInvertido;
    final idIzq = izqEsA ? widget.ladoAId : widget.ladoBId;
    final idDer = izqEsA ? widget.ladoBId : widget.ladoAId;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: LayoutBuilder(
          builder: (ctx, constraints) => SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints:
                  BoxConstraints(minWidth: constraints.maxWidth),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    mitadIzq(idIzq),
                    Container(
                        width: 10, height: 340, color: Colors.black),
                    mitadDer(idDer),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _banca() {
    final bA = _bancaIds(true);
    final bB = _bancaIds(false);
    Widget col(String titulo, List<String> ids) {
      return Expanded(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Banca $titulo',
                    style:
                        const TextStyle(fontWeight: FontWeight.bold)),
                ...ids.map((id) => Text(
                    '• ${_nombreJug(id)}')),
                if (ids.isEmpty)
                  const Text('Sin banca',
                      style: TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(children: [
          col(_nombre(widget.ladoAId), bA),
          const SizedBox(width: 8),
          col(_nombre(widget.ladoBId), bB),
        ]),
        ElevatedButton.icon(
          icon: const Icon(Icons.person_add),
          label: const Text(
              'Registrar número a jugador tardío (de cédula)'),
          onPressed: () => _dialogoTardio(),
        ),
      ],
    );
  }

  void _dialogoTardio() {
    final t = _torneo();
    final candidatos = <String, String>{}; // jugId -> etiqueta
    for (final eq in [widget.ladoAId, widget.ladoBId]) {
      final team = t.equipoPorId(eq)!;
      for (final j in team.jugadores) {
        if (j.numero == null) {
          candidatos[j.id] =
              '${team.nombre}: ${j.nombreCompleto}';
        }
      }
    }
    if (candidatos.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('No hay jugadores sin número en cédula.')));
      return;
    }
    String? sel;
    final numC = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (c, setS) {
        return AlertDialog(
          title: const Text('Registrar número tardío'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Jugador de cédula'),
                value: sel,
                items: candidatos.entries
                    .map((e) => DropdownMenuItem(
                        value: e.key, child: Text(e.value)))
                    .toList(),
                onChanged: (v) => setS(() => sel = v),
              ),
              TextField(
                  controller: numC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                      labelText: 'Número (0-99)')),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                if (sel == null) return;
                final n = int.tryParse(numC.text.trim());
                if (n == null) return;
                String eqId = '';
                for (final eq in [widget.ladoAId, widget.ladoBId]) {
                  final team = t.equipoPorId(eq)!;
                  if (team.jugadores.any((j) => j.id == sel)) {
                    eqId = eq;
                  }
                }
                final team = t.equipoPorId(eqId)!;
                if (team.jugadores
                    .any((j) => j.numero == n)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text(
                              'Número $n duplicado en ${team.nombre}')));
                  return;
                }
                team.jugadores
                    .firstWhere((j) => j.id == sel)
                    .numero = n;
                final fix = _fixture();
                if (fix.equipoAId == eqId) {
                  acc.jugA.add(sel!);
                } else {
                  acc.jugB.add(sel!);
                }
                context.read<AppStore>().persistir();
                setState(() {});
                Navigator.pop(context);
              },
              child: const Text('Guardar')),
          ],
        );
      }),
    );
  }

  /// (8) Cambios FIVB estrictos con listas filtradas en ambos sentidos.
  void _dialogoCambio(bool paraA) {
    final activos = paraA ? posA : posB;
    final banca = _bancaIds(paraA);
    final ctrl = paraA ? subA : subB;
    final tit = paraA ? titA : titB;
    if (!ctrl.puedeSustituir) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content:
              Text('Máximo 6 sustituciones por set (FIVB).')));
      return;
    }
    if (banca.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay banca disponible.')));
      return;
    }
    String? sale, entra;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (c, setS) {
        // Filtrado dinámico: solo opciones reales según el reglamento.
        List<String> entraOpts = banca;
        List<String> saleOpts = activos;
        if (sale != null) {
          entraOpts = ctrl.entradasLegalesPara(sale!, banca, tit);
          if (entra != null && !entraOpts.contains(entra)) entra = null;
        }
        if (entra != null) {
          saleOpts = ctrl.salidasLegalesPara(entra!, activos, tit);
          if (sale != null && !saleOpts.contains(sale)) sale = null;
        }
        String? err;
        if (sale != null && entra != null) {
          err = ctrl.validar(sale!, entra!, tit);
        }
        return AlertDialog(
          title: const Text(
              'Solicitud de cambio (FIVB: 6/set, reingreso 1 vez)'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Sale (6 activos)'),
                value: sale,
                items: saleOpts
                    .map((id) => DropdownMenuItem(
                        value: id, child: Text(_nombreJug(id))))
                    .toList(),
                onChanged: (v) => setS(() => sale = v),
              ),
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Entra (banca)'),
                value: entra,
                items: entraOpts
                    .map((id) => DropdownMenuItem(
                        value: id, child: Text(_nombreJug(id))))
                    .toList(),
                onChanged: (v) => setS(() => entra = v),
              ),
              const Text(
                  'El titular solo vuelve por su sustituto; el sustituto solo sale por su titular original.',
                  style: TextStyle(fontSize: 11, color: Colors.grey)),
              if (sale != null && entraOpts.isEmpty)
                const Text('Ese jugador no tiene relevo legal disponible.',
                    style: TextStyle(color: Colors.red)),
              if (entra != null && saleOpts.isEmpty)
                const Text('Nadie puede salir legalmente por ese jugador.',
                    style: TextStyle(color: Colors.red)),
              if (err != null)
                Text(err,
                    style:
                        const TextStyle(color: Colors.red)),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            TextButton(
              onPressed: (sale == null ||
                      entra == null ||
                      err != null)
                  ? null
                  : () {
                      ctrl.registrar(sale!, entra!, tit);
                      setState(() {
                        final idx = activos.indexOf(sale!);
                        activos[idx] = entra!;
                      });
                      Navigator.pop(context);
                    },
              child: const Text('Sustituir'),
            ),
          ],
        );
      }),
    );
  }

  void _dialogoSancion() {
    String? tipo = tiposSancion.first;
    String? eqId = widget.ladoAId;
    String? jugSel; // id o 'EQUIPO'
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (c, setS) {
        final activos = (eqId == widget.ladoAId ? posA : posB);
        final banca = _bancaIds(eqId == widget.ladoAId);
        final opciones = [
          ...activos.map((id) => '${_nombreJug(id)} (activo)::$id'),
          ...banca.map((id) => '${_nombreJug(id)} (banca)::$id'),
        ];
        return AlertDialog(
          title: const Text('Registrar sanción'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<String>(
                  isExpanded: true,
                  value: tipo,
                  items: tiposSancion
                      .map((e) => DropdownMenuItem(
                          value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setS(() => tipo = v),
                ),
                DropdownButton<String>(
                  isExpanded: true,
                  value: eqId,
                  items: [widget.ladoAId, widget.ladoBId]
                      .map((id) => DropdownMenuItem(
                          value: id,
                          child: Text(_nombre(id))))
                      .toList(),
                  onChanged: (v) =>
                      setS(() {
                        eqId = v;
                        jugSel = null;
                      }),
                ),
                DropdownButton<String>(
                  isExpanded: true,
                  hint: const Text('Jugador o Equipo'),
                  value: jugSel,
                  items: [
                    const DropdownMenuItem(
                        value: 'EQUIPO',
                        child: Text('Equipo (sanción grupal)')),
                    ...opciones.map((o) {
                      final partes = o.split('::');
                      return DropdownMenuItem(
                          value: partes[1],
                          child: Text(partes[0]));
                    }),
                  ],
                  onChanged: (v) =>
                      setS(() => jugSel = v),
                ),
                Text(
                    'Set ${widget.setNumero} • Marcador $pA-$pB',
                    style:
                        const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar')),
            TextButton(
              onPressed: jugSel == null
                  ? null
                  : () {
                      final grupal = jugSel == 'EQUIPO';
                      String? nom;
                      int? num;
                      if (!grupal) {
                        nom = _nombreJug(jugSel!);
                        num = _numeroJug(jugSel!);
                      }
                      acc.sanciones.add(Sanction(
                          tipo: tipo!,
                          equipoId: eqId!,
                          jugadorNombre: nom,
                          jugadorNumero: num,
                          grupal: grupal,
                          set: widget.setNumero,
                          marcadorA: pA,
                          marcadorB: pB));
                      setState(() {});
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Sanción guardada para la hoja final.')));
                    },
              child: const Text('Guardar')),
          ],
        );
      }),
    );
  }
}
