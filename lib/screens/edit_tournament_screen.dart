import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../store.dart';
import 'teams_screen.dart';

class EditTournamentScreen extends StatelessWidget {
  final String torneoId;
  const EditTournamentScreen({super.key, required this.torneoId});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final t = store.porId(torneoId)!;
    return Scaffold(
      appBar: AppBar(title: const Text('Editar torneo')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Agregar equipo nuevo',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  _NuevoEquipo(torneoId: torneoId),
                  const Text(
                      'Si el torneo ya inició, las demás pantallas se actualizan y muestran el nuevo equipo.',
                      style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ),
          ...t.equipos.map((eq) => Card(
                child: ListTile(
                  title: Text('${eq.nombre} (${eq.jugadores.length})'),
                  trailing: TextButton(
                    child: const Text('Editar cédula'),
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CedulaScreen(
                                torneoId: torneoId,
                                equipoId: eq.id))),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}

class _NuevoEquipo extends StatefulWidget {
  final String torneoId;
  const _NuevoEquipo({required this.torneoId});
  @override
  State<_NuevoEquipo> createState() => _S();
}

class _S extends State<_NuevoEquipo> {
  final _c = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: TextField(
                controller: _c,
                decoration: const InputDecoration(
                    labelText: 'Nombre del equipo'))),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () async {
            if (_c.text.trim().isEmpty) return;
            final store = context.read<AppStore>();
            final t = store.porId(widget.torneoId)!;
            await store.agregarEquipoATorneo(
                t, Team(nombre: _c.text.trim()));
            _c.clear();
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Equipo agregado y pantallas actualizadas.')));
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}
