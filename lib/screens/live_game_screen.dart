import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../store.dart';
import '../rules.dart';
import 'side_serve_screen.dart';
import 'lineup_screen.dart';

class _Acc {
  int setsFA = 0;
  int setsFB = 0;
  List<String> parciales = [];
  List<Sanction> sanciones = [];
  Set<String> jugA = {};
  Set<String> jugB = {};
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
      this.prevB});

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

  @override
  void initState() {
    super.initState();
    posA = List<String>.from(widget.lineupA);
    posB = List<String>.from(widget.lineupB);
    saca = widget.saqueId;
    subA = ControlSustituciones();
    subB = ControlSustituciones();
    titA = posA.toSet();
    titB = posB.toSet();
    // registrar jugadores que participan
    final t = _torneo();
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
    t.toString();
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
    return id.substring(0, 4);
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
        // si cambia el saque, rota el que gana
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
      // cambio de lado automático en definitivo a los 8 puntos
      final f = _torneo().formato;
      if (esSetDefinitivo(widget.setNumero, f) &&
          !cambioDefinitivoHecho &&
          (pA + pB) >= 8) {
        cambioDefinitivoHecho = true;
        ladoInvertido = !ladoInvertido;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Set definitivo: 8 puntos, cambio de lado automático')));
      }
      _verificarFinSet();
    });
  }

  void _verificarFinSet() {
    final f = _torneo().formato;
    if (!ganaSet(pA, pB, widget.setNumero, f)) return;
    setTerminado = true;
    final ganoA = pA > pB;
    // parcial en orden fixture
    final fix = _fixture();
    String parcial;
    if (fix.equipoAId == widget.ladoAId) {
      parcial = '$pA-$pB';
    } else {
      parcial = '$pB-$pA';
    }
    acc.parciales.add(parcial);
    if ((fix.equipoAId == widget.ladoAId && ganoA) ||
        (fix.equipoBId == widget.ladoAId && ganoA)) {
      // ladoA ganó el set
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
    // registrar jugadores del set
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
    // construir snapshots
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

    final jugA = fix.equipoAId == widget.ladoAId
        ? {...acc.jugA}
        : {...acc.jugB};
    // acc guarda en orden fixture ya; jugA/jugB ya están en fixture.
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
              );
              LiveGameScreen.sesiones
                  .remove('${widget.torneoId}_${widget.matchId}');
              await store.guardarResultado(t, fix, r);
              if (!context.mounted) return;
              Navigator.popUntil(context, (ro) => ro.isFirst);
              jugA.toString();
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
      // incluir acumulados previos de ese lado
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

  @override
  Widget build(BuildContext context) {
    final ladoA = widget.ladoAId;
    final ladoB = widget.ladoBId;
    // orden visual
    final izqEsA = !ladoInvertido;
    final idIzq = izqEsA ? ladoA : ladoB;
    final idDer = izqEsA ? ladoB : ladoA;
    final pIzq = izqEsA ? pA : pB;
    final pDer = izqEsA ? pB : pA;
    final setsIzq =
        _setsDe(idIzq);
    final setsDer = _setsDe(idDer);

    return Scaffold(
      appBar: AppBar(
          title: Text(
              '${_nombre(ladoA)} vs ${_nombre(ladoB)} • Set ${widget.setNumero}')),
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
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _marcador(idIzq, pIzq, true),
              const Text(':', style: TextStyle(fontSize: 40)),
              _marcador(idDer, pDer, false),
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
        ],
      ),
    );
  }

  int _setsDe(String teamId) {
    final fix = _fixture();
    if (teamId == fix.equipoAId) return acc.setsFA;
    return acc.setsFB;
  }

  Widget _marcador(String teamId, int pts, bool esA) {
    final esLadoA = (teamId == widget.ladoAId);
    final isA = esLadoA ? true : false;
    // paraA se refiere a ladoA original
    final paraA = teamId == widget.ladoAId;
    return Column(
      children: [
        Text(_nombre(teamId),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('$pts',
            style: const TextStyle(
                fontSize: 56, fontWeight: FontWeight.bold)),
        Row(
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
          children: [
            ElevatedButton(
              onPressed: () => _pedirTiempo(paraA),
              child: Text(
                  'Tiempo (${paraA ? tA : tB}/2)'),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _dialogoCambio(paraA),
              child: Text(
                  'Cambio (${paraA ? subA.usadas : subB.usadas}/6)'),
            ),
          ],
        ),
        if (saca == teamId)
          const Text('● SAQUE',
              style: TextStyle(
                  color: Colors.orange, fontWeight: FontWeight.bold)),
        isA.toString().isEmpty ? const SizedBox() : const SizedBox(),
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

  Widget _cancha() {
    // pos: idx0=p1 ... idx5=p6
    Widget celda(String id, bool conSaque) {
      final num = _numeroJug(id)?.toString() ?? '?';
      return Container(
        width: 64,
        height: 64,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: conSaque ? Colors.yellow : Colors.blue.shade50,
          border: Border.all(color: Colors.blueGrey, width: 2),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Center(
            child: Text(num,
                style: const TextStyle(
                    fontSize: 26, fontWeight: FontWeight.bold))),
      );
    }

    String sacaA = saca == widget.ladoAId ? posA[0] : '';
    String sacaB = saca == widget.ladoBId ? posB[0] : '';

    Widget ladoA() {
      return Column(
        children: [
          Text(_nombre(widget.ladoAId),
              style:
                  const TextStyle(fontWeight: FontWeight.bold)),
          Row(children: [
            Column(children: [
              celda(posA[4], posA[4] == sacaA),
              celda(posA[5], posA[5] == sacaA),
              celda(posA[0], posA[0] == sacaA),
            ]),
            Column(children: [
              celda(posA[3], posA[3] == sacaA),
              celda(posA[2], posA[2] == sacaA),
              celda(posA[1], posA[1] == sacaA),
            ]),
          ]),
          const Text('5-4 / 6-3 / 1-2',
              style: TextStyle(fontSize: 10)),
        ],
      );
    }

    Widget ladoB() {
      return Column(
        children: [
          Text(_nombre(widget.ladoBId),
              style:
                  const TextStyle(fontWeight: FontWeight.bold)),
          Row(children: [
            Column(children: [
              celda(posB[1], posB[1] == sacaB),
              celda(posB[2], posB[2] == sacaB),
              celda(posB[3], posB[3] == sacaB),
            ]),
            Column(children: [
              celda(posB[0], posB[0] == sacaB),
              celda(posB[5], posB[5] == sacaB),
              celda(posB[4], posB[4] == sacaB),
            ]),
          ]),
          const Text('2-1 / 3-6 / 4-5',
              style: TextStyle(fontSize: 10)),
        ],
      );
    }

    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          children: [
            const Text(
                'ZAGUERO • ATAQUE • RED • ATAQUE • ZAGUERO',
                style: TextStyle(fontSize: 11)),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ladoInvertido ? ladoB() : ladoA(),
                Container(
                    width: 8,
                    height: 240,
                    color: Colors.red,
                    child: const Center(
                        child: RotatedBox(
                            quarterTurns: 1,
                            child: Text('RED',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontWeight:
                                        FontWeight.bold))))),
                ladoInvertido ? ladoA() : ladoB(),
              ],
            ),
            const Text(
                'Rotación en manecillas del reloj • ● amarillo = saque',
                style: TextStyle(fontSize: 11)),
          ],
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
    // jugadores de cédula sin número
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
                // verificar duplicado en su equipo
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
                // agregar a acumulados
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
                items: activos
                    .map((id) => DropdownMenuItem(
                        value: id, child: Text(_nombreJug(id))))
                    .toList(),
                onChanged: (v) => setS(() => sale = v),
              ),
              DropdownButton<String>(
                isExpanded: true,
                hint: const Text('Entra (banca)'),
                value: entra,
                items: banca
                    .map((id) => DropdownMenuItem(
                        value: id, child: Text(_nombreJug(id))))
                    .toList(),
                onChanged: (v) => setS(() => entra = v),
              ),
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
    final t = _torneo();
    String? tipo = tiposSancion.first;
    String? eqId = widget.ladoAId;
    String? jugSel; // id o 'EQUIPO'
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (c, setS) {
        final team = t.equipoPorId(eqId!)!;
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
                      team.toString();
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
