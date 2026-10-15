import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'teams_screen.dart';

class EditTournamentScreen extends StatelessWidget {
  final String torneoId;
  const EditTournamentScreen({super.key, required this.torneoId});

  void _confirmBaja(
      BuildContext context, AppStore store, Tournament t, Team eq) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Dar de baja al equipo'),
        content: Text(
            '"${eq.nombre}" sale del torneo.\nSus partidos se registran como derrota 25-0 por set a favor de cada rival.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () async {
              await store.darDeBajaEquipo(t, eq.id);
              if (!context.mounted) return;
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      '${eq.nombre} dado de baja (rivales ganan 25-0).')));
            },
            child: const Text('Dar de baja'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final t = store.porId(torneoId)!;
    return Scaffold(
      appBar: AppBar(title: const Text('Editar torneo')),
      body: AppBg(
        child: ListView(
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
          ...t.equipos.map((eq) {
            final baja = t.estaDeBaja(eq.id);
            return Card(
              color: baja ? Colors.red.shade50 : null,
              child: ListTile(
                title: Text(
                    '${eq.nombre} (${eq.jugadores.length})${baja ? ' — BAJA' : ''}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextButton(
                      child: const Text('Editar cédula'),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => CedulaScreen(
                                  torneoId: torneoId,
                                  equipoId: eq.id))),
                    ),
                    if (!baja)
                      TextButton(
                        child: const Text('Baja',
                            style: TextStyle(color: Colors.red)),
                        onPressed: () =>
                            _confirmBaja(context, store, t, eq),
                      ),
                  ],
                ),
              ),
            );
          }),
          ],
        ),
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
