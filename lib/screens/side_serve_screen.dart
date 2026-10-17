import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../store.dart';
import 'lineup_screen.dart';

/// Selección de lado (quién es lado A) y saque inicial.
class SideServeScreen extends StatefulWidget {
  final String torneoId;
  final String matchId;
  final int setNumero;
  final bool esDefinitivo;
  /// Lado heredado del set anterior (true = lado A a la derecha).
  final bool invertido;
  const SideServeScreen(
      {super.key,
      required this.torneoId,
      required this.matchId,
      this.setNumero = 1,
      this.esDefinitivo = false,
      this.invertido = false});

  @override
  State<SideServeScreen> createState() => _State();
}

class _State extends State<SideServeScreen> {
  String? ladoAId;
  String? saqueId;

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final t = store.porId(widget.torneoId)!;
    final m = t.fixture.firstWhere((e) => e.id == widget.matchId);
    ladoAId ??= m.equipoAId;
    saqueId ??= m.equipoAId;
    final ids = [m.equipoAId, m.equipoBId];
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.setNumero == 1
              ? 'Lado y saque inicial'
              : 'Lado y saque - Set ${widget.setNumero}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.esDefinitivo)
              const Card(
                  child: Padding(
                      padding: EdgeInsets.all(12),
                      child: Text(
                          'Set definitivo: elige de nuevo lado y saque inicial. A los 8 puntos se cambiará de lado automáticamente.'))),
            const Text('¿Quién es el equipo del lado A?',
                style: TextStyle(fontWeight: FontWeight.bold)),
            if (widget.setNumero > 1)
              Padding(
                padding: const EdgeInsets.only(left: 12, bottom: 4),
                child: Text(
                    'En este set el lado A queda a la ${widget.invertido ? 'derecha' : 'izquierda'} (cambian de lado respecto al set anterior).',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ...ids.map((id) => RadioListTile<String>(
                  title: Text(t.nombreEquipo(id)),
                  value: id,
                  groupValue: ladoAId,
                  onChanged: (v) => setState(() => ladoAId = v),
                )),
            const SizedBox(height: 12),
            const Text('¿Quién tiene el saque inicial?',
                style: TextStyle(fontWeight: FontWeight.bold)),
            ...ids.map((id) => RadioListTile<String>(
                  title: Text(t.nombreEquipo(id)),
                  value: id,
                  groupValue: saqueId,
                  onChanged: (v) => setState(() => saqueId = v),
                )),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text('Guardar y continuar'),
                onPressed: () {
                  // ladoB es el otro
                  final ladoBId =
                      ids.firstWhere((e) => e != ladoAId);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => LineupScreen(
                                torneoId: widget.torneoId,
                                matchId: widget.matchId,
                                ladoAId: ladoAId!,
                                ladoBId: ladoBId,
                                saqueId: saqueId!,
                                setNumero: widget.setNumero,
                                invertido: widget.invertido,
                              )));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
