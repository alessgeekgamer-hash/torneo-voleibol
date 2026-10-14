import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../store.dart';
import '../models.dart';
import 'tournament_form.dart';
import 'dashboard.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Scaffold(
      appBar: AppBar(title: const Text('Control de Torneo de Voleibol')),
      drawer: Drawer(
        child: ListView(
          children: [
            const DrawerHeader(
                child: Text('Configuración',
                    style: TextStyle(fontSize: 20))),
            SwitchListTile(
              title: const Text('Tono oscuro'),
              value: store.oscuro,
              onChanged: (_) => store.toggleOscuro(),
            ),
            const Divider(),
            const Padding(
              padding: EdgeInsets.all(12),
              child: Text('Borrado de torneos: mantén presionado un torneo en "Continuar torneo" o usa el icono de borrar.'),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Agregar torneo'),
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const TournamentFormScreen())),
            ),
            const SizedBox(height: 12),
            const Text('Continuar torneo:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Expanded(
              child: store.torneos.isEmpty
                  ? const Center(
                      child: Text('No hay torneos guardados.'))
                  : ListView.builder(
                      itemCount: store.torneos.length,
                      itemBuilder: (c, i) {
                        final t = store.torneos[i];
                        return Card(
                          child: ListTile(
                            title: Text(t.nombre),
                            subtitle: Text(
                                '${formatoLabel(t.formato)} • ${sistemaLabel(t.sistema)} • ${t.equipos.length} equipos'),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () =>
                                  _confirmDelete(context, store, t),
                            ),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        DashboardScreen(torneoId: t.id))),
                            onLongPress: () =>
                                _confirmDelete(context, store, t),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, AppStore store, Tournament t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Borrar torneo'),
        content: Text('¿Eliminar "${t.nombre}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              store.eliminarTorneo(t.id);
              Navigator.pop(context);
            },
            child:
                const Text('Borrar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
