import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../responsive.dart';
import '../store.dart';
import 'live_game_screen.dart';

/// Captura de posiciones iniciales 1-6. Arriba el equipo con saque.
/// Si [pausa] viene informada, es reanudación: se captura la alineación
/// para lo que resta del set (los cambios se reinician desde ahí).
class LineupScreen extends StatefulWidget {
  final String torneoId;
  final String matchId;
  final String ladoAId;
  final String ladoBId;
  final String saqueId;
  final int setNumero;
  final List<String>? prevA;
  final List<String>? prevB;
  final PausaPartido? pausa;
  /// Lado invertido con el que entra el set (true = lado A a la derecha).
  final bool invertido;
  const LineupScreen(
      {super.key,
      required this.torneoId,
      required this.matchId,
      required this.ladoAId,
      required this.ladoBId,
      required this.saqueId,
      required this.setNumero,
      this.prevA,
      this.prevB,
      this.pausa,
      this.invertido = false});

  @override
  State<LineupScreen> createState() => _State();
}

class _State extends State<LineupScreen> {
  String? selA1, selA2, selA3, selA4, selA5, selA6;
  String? selB1, selB2, selB3, selB4, selB5, selB6;
  // Controladores para escribir el número directo por posición.
  final Map<String, TextEditingController> _numCtrl = {};

  List<Player> conNumero(Team t) =>
      t.jugadores.where((j) => j.numero != null).toList();

  @override
  void dispose() {
    for (final c in _numCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  String? _get(bool arriba, int p) => arriba ? _getA(p) : _getB(p);
  void _set(bool arriba, int p, String? v) {
    if (arriba) {
      _setA(p, v);
    } else {
      _setB(p, v);
    }
  }

  List<String?> _vals(bool arriba) => arriba
      ? [selA1, selA2, selA3, selA4, selA5, selA6]
      : [selB1, selB2, selB3, selB4, selB5, selB6];

  /// Escribe el número y lo liga con el jugador registrado con ese número.
  void _porNumero(bool arriba, int pos, String txt, List<Player> jugadores) {
    final n = int.tryParse(txt.trim());
    if (n == null) return;
    Player? cand;
    for (final j in jugadores) {
      if (j.numero == n) {
        cand = j;
        break;
      }
    }
    if (cand == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Ningún jugador registrado con el #$n')));
      return;
    }
    final otros = _vals(arriba).whereType<String>().toSet()
      ..remove(_get(arriba, pos));
    if (otros.contains(cand.id)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
              '#$n (${cand.nombreCompleto}) ya está en otra posición')));
      return;
    }
    setState(() => _set(arriba, pos, cand!.id));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final t = store.porId(widget.torneoId)!;
    final eqA = t.equipoPorId(widget.ladoAId)!;
    final eqB = t.equipoPorId(widget.ladoBId)!;
    // arriba va el que tiene el saque
    final arribaEsA = widget.saqueId == widget.ladoAId;
    final eqArriba = arribaEsA ? eqA : eqB;
    final eqAbajo = arribaEsA ? eqB : eqA;

    return Scaffold(
      appBar: AppBar(title: Text(widget.pausa != null
          ? 'Alineación para reanudar - Set ${widget.setNumero}'
          : 'Alineación - Set ${widget.setNumero}')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (widget.pausa != null)
            const Card(
                child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                        'Captura la alineación para lo que resta del set (pueden ser jugadoras diferentes). Los cambios se reinician desde esta alineación; el marcador y los sets se conservan.'))),
          Text(
              'Arriba: ${eqArriba.nombre} (saque) • Abajo: ${eqAbajo.nombre} (recibe)',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          Builder(builder: (_) {
            final inv = widget.pausa?.ladoInvertido ?? widget.invertido;
            final izq = inv ? widget.ladoBId : widget.ladoAId;
            final der = inv ? widget.ladoAId : widget.ladoBId;
            return Text(
                'Lados: ${t.nombreEquipo(izq)} a la izquierda • '
                '${t.nombreEquipo(der)} a la derecha',
                style: const TextStyle(fontSize: 12, color: Colors.grey));
          }),
          const SizedBox(height: 8),
          MaxWidth(
              child: _bloque(
                  'Equipo ${eqArriba.nombre} (arriba)', eqArriba, true)),
          const SizedBox(height: 8),
          MaxWidth(
              child: _bloque(
                  'Equipo ${eqAbajo.nombre} (abajo)', eqAbajo, false)),
          const SizedBox(height: 12),
          MaxWidth(
            child: ElevatedButton(
              onPressed: () {
              // mapear a orden ladoA/ladoB reales
              List<String?> linA, linB;
              if (arribaEsA) {
                linA = [selA1, selA2, selA3, selA4, selA5, selA6];
                linB = [selB1, selB2, selB3, selB4, selB5, selB6];
              } else {
                // en UI _bloque(true) fue eqArriba=eqB pero guardado en selA*;
                // reconvertimos:
                linB = [selA1, selA2, selA3, selA4, selA5, selA6];
                linA = [selB1, selB2, selB3, selB4, selB5, selB6];
              }
              if (linA.any((e) => e == null) || linB.any((e) => e == null)) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Completa las 6 posiciones de cada equipo')));
                return;
              }
              if (linA.toSet().length != 6 || linB.toSet().length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('No repitas jugadores en el mismo equipo')));
                return;
              }
              // construir mapas id->player para live
              if (widget.pausa != null) {
                Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => LiveGameScreen.reanudar(
                              pausa: widget.pausa!,
                              lineupA: linA.cast<String>(),
                              lineupB: linB.cast<String>(),
                            )));
                return;
              }
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => LiveGameScreen(
                            torneoId: widget.torneoId,
                            matchId: widget.matchId,
                            ladoAId: widget.ladoAId,
                            ladoBId: widget.ladoBId,
                            saqueId: widget.saqueId,
                            setNumero: widget.setNumero,
                            lineupA: linA.cast<String>(),
                            lineupB: linB.cast<String>(),
                            prevA: widget.prevA,
                            prevB: widget.prevB,
                            ladoInicialInvertido: widget.invertido,
                          )));
            },
            child: const Text('Continuar al juego'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bloque(String titulo, Team eq, bool esArriba) {
    final jugadores = conNumero(eq);
    // (6) excluir ya elegidos en otras posiciones del mismo equipo
    Set<String> elegidos(bool arriba) {
      final vals = arriba
          ? [selA1, selA2, selA3, selA4, selA5, selA6]
          : [selB1, selB2, selB3, selB4, selB5, selB6];
      return vals.whereType<String>().toSet();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(titulo,
                style: const TextStyle(fontWeight: FontWeight.bold)),
            for (var pos = 1; pos <= 6; pos++)
              Builder(builder: (_) {
                final actual =
                    esArriba ? _getA(pos) : _getB(pos);
                final otros = elegidos(esArriba)..remove(actual);
                final disponibles = jugadores
                    .where((j) => !otros.contains(j.id))
                    .toList();
                // Sincroniza el campo de número con la selección actual
                // (solo cuando el usuario no lo está editando).
                final key = '${esArriba ? 'A' : 'B'}$pos';
                final nc = _numCtrl.putIfAbsent(
                    key, () => TextEditingController());
                return Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                            labelText: 'Posición $pos'),
                        value: actual,
                        items: disponibles
                            .map((j) => DropdownMenuItem(
                                value: j.id,
                                child: Text(
                                    '#${j.numero} ${j.nombreCompleto}')))
                            .toList(),
                        onChanged: (v) => setState(() {
                          if (esArriba) {
                            _setA(pos, v);
                          } else {
                            _setB(pos, v);
                          }
                          if (v != null) {
                            for (final j in jugadores) {
                              if (j.id == v) {
                                nc.text =
                                    j.numero?.toString() ?? '';
                                break;
                              }
                            }
                          } else {
                            nc.clear();
                          }
                        }),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 72,
                      child: TextField(
                        controller: nc,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: '#',
                            border: OutlineInputBorder()),
                        onChanged: (txt) =>
                            _porNumero(esArriba, pos, txt, jugadores),
                      ),
                    ),
                  ],
                );
              }),
          ],
        ),
      ),
    );
  }

  String? _getA(int p) {
    switch (p) {
      case 1:
        return selA1;
      case 2:
        return selA2;
      case 3:
        return selA3;
      case 4:
        return selA4;
      case 5:
        return selA5;
      default:
        return selA6;
    }
  }

  String? _getB(int p) {
    switch (p) {
      case 1:
        return selB1;
      case 2:
        return selB2;
      case 3:
        return selB3;
      case 4:
        return selB4;
      case 5:
        return selB5;
      default:
        return selB6;
    }
  }

  void _setA(int p, String? v) {
    switch (p) {
      case 1:
        selA1 = v;
        break;
      case 2:
        selA2 = v;
        break;
      case 3:
        selA3 = v;
        break;
      case 4:
        selA4 = v;
        break;
      case 5:
        selA5 = v;
        break;
      default:
        selA6 = v;
    }
  }

  void _setB(int p, String? v) {
    switch (p) {
      case 1:
        selB1 = v;
        break;
      case 2:
        selB2 = v;
        break;
      case 3:
        selB3 = v;
        break;
      case 4:
        selB4 = v;
        break;
      case 5:
        selB5 = v;
        break;
      default:
        selB6 = v;
    }
  }
}
