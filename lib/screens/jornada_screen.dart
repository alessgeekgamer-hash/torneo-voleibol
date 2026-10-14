import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../store.dart';
import 'roster_screen.dart';

class JornadaScreen extends StatelessWidget {
  final String torneoId;
  const JornadaScreen({super.key, required this.torneoId});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final t = store.porId(torneoId)!;
    final partidos = t.fixture
        .where((m) =>
            m.programado &&
            !t.resultados.any((r) => r.matchId == m.id))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Jornada actual')),
      body: partidos.isEmpty
          ? const Center(
              child: Text(
                  'No hay partidos programados.\nActívalos en Rol de juegos.',
                  textAlign: TextAlign.center))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: partidos.length,
              itemBuilder: (c, i) {
                final m = partidos[i];
                return Card(
                  child: ListTile(
                    title: Text(
                        '${t.nombreEquipo(m.equipoAId)} vs ${t.nombreEquipo(m.equipoBId)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(m.etiqueta),
                    trailing: ElevatedButton(
                      child: const Text('Iniciar encuentro'),
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => RosterScreen(
                                  torneoId: torneoId,
                                  matchId: m.id))),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
