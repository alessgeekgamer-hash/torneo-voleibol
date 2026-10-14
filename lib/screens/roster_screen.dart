import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../store.dart';
import 'side_serve_screen.dart';

/// Captura de roster: lista de jugadores de cada equipo + número de playera.
/// Valida duplicados por equipo. Permite capturar nuevo jugador (igual que cédula).
/// Solo jugadores con número se guardan para el partido.
class RosterScreen extends StatefulWidget {
  final String torneoId;
  final String matchId;
  const RosterScreen(
      {super.key, required this.torneoId, required this.matchId});

  @override
  State<RosterScreen> createState() => _State();
}

class _State extends State<RosterScreen> {
  final Map<String, TextEditingController> _nums = {};

  @override
  void dispose() {
    for (final c in _nums.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _ctrl(Player j) {
    return _nums.putIfAbsent(
        j.id, () => TextEditingController(text: j.numero?.toString() ?? ''));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final t = store.porId(widget.torneoId)!;
    final m = t.fixture.firstWhere((e) => e.id == widget.matchId);
    final eqA = t.equipoPorId(m.equipoAId)!;
    final eqB = t.equipoPorId(m.equipoBId)!;
    return Scaffold(
      appBar: AppBar(title: const Text('Roster del encuentro')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _equipoBlock(context, store, t, eqA),
          const SizedBox(height: 12),
          _equipoBlock(context, store, t, eqB),
          const SizedBox(height: 16),
          ElevatedButton(
            child: const Text('Guardar y elegir lado / saque'),
            onPressed: () {
              // validar duplicados y guardar números en cédula temporal
              for (final eq in [eqA, eqB]) {
                final vistos = <String>{};
                for (final j in eq.jugadores) {
                  final txt = _ctrl(j).text.trim();
                  if (txt.isEmpty) {
                    j.numero = null;
                    continue;
                  }
                  final n = int.tryParse(txt);
                  if (n == null || n < 0 || n > 99) {
                    _error('Número inválido para ${j.nombreCompleto} (0-99).');
                    return;
                  }
                  if (vistos.contains(txt)) {
                    _error('Número duplicado #$txt en ${eq.nombre}.');
                    return;
                  }
                  vistos.add(txt);
                  j.numero = n;
                }
              }
              final conA =
                  eqA.jugadores.where((j) => j.numero != null).length;
              final conB =
                  eqB.jugadores.where((j) => j.numero != null).length;
              if (conA < 6 || conB < 6) {
                _error(
                    'Cada equipo necesita al menos 6 jugadores con número (A:$conA B:$conB).');
                return;
              }
              store.persistir();
              _pedirFechaLugar(context, store, t, m);
            },
          ),
        ],
      ),
    );
  }

  Widget _equipoBlock(
      BuildContext context, AppStore store, Tournament t, Team eq) {
    final conNumero =
        eq.jugadores.where((j) => _ctrl(j).text.trim().isNotEmpty).length;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                    child: Text(eq.nombre,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold))),
                Text('$conNumero con número'),
              ],
            ),
            const SizedBox(height: 8),
            ...eq.jugadores.map((j) => Row(
                  children: [
                    Expanded(
                        child: Text(j.nombreCompleto,
                            overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 80,
                      child: TextField(
                        controller: _ctrl(j),
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                            labelText: '#', border: OutlineInputBorder()),
                        onChanged: (_) => setState(() {}),
                      ),
                    ),
                  ],
                )),
            TextButton.icon(
              icon: const Icon(Icons.person_add),
              label: const Text('Capturar nuevo jugador'),
              onPressed: () => _nuevoJugador(context, store, eq),
            ),
          ],
        ),
      ),
    );
  }

  void _nuevoJugador(BuildContext context, AppStore store, Team eq) {
    final nombre = TextEditingController();
    final apellido = TextEditingController();
    final nac = TextEditingController();
    final tel = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Nuevo jugador - ${eq.nombre}'),
        content: SingleChildScrollView(
          child: Column(children: [
            TextField(controller: nombre, decoration: const InputDecoration(labelText: 'Nombre *')),
            TextField(controller: apellido, decoration: const InputDecoration(labelText: 'Apellido')),
            TextField(controller: nac, decoration: const InputDecoration(labelText: 'Fecha de nacimiento')),
            TextField(controller: tel, decoration: const InputDecoration(labelText: 'Teléfono')),
          ]),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              if (nombre.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('El nombre es obligatorio')));
                return;
              }
              final j = Player(
                  nombre: nombre.text.trim(),
                  apellido: apellido.text.trim(),
                  fechaNacimiento: nac.text.trim(),
                  telefono: tel.text.trim());
              eq.jugadores.add(j);
              store.persistir();
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  /// (4) Pantalla emergente de fecha y lugar del partido.
  void _pedirFechaLugar(
      BuildContext context, AppStore store, Tournament t, Match m) {
    final fechaC = TextEditingController(
        text: m.fecha.isEmpty
            ? DateTime.now().toString().substring(0, 10)
            : m.fecha);
    final lugarC = TextEditingController(text: m.lugar);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text('Fecha y lugar del partido'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: fechaC,
                decoration: const InputDecoration(
                    labelText: 'Fecha (AAAA-MM-DD)',
                    border: OutlineInputBorder())),
            const SizedBox(height: 10),
            TextField(
                controller: lugarC,
                decoration: const InputDecoration(
                    labelText: 'Lugar / cancha',
                    border: OutlineInputBorder())),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              m.fecha = fechaC.text.trim();
              m.lugar = lugarC.text.trim();
              store.persistir();
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SideServeScreen(
                          torneoId: widget.torneoId,
                          matchId: widget.matchId)));
            },
            child: const Text('Guardar y continuar'),
          ),
        ],
      ),
    );
  }
}
