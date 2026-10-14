import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../store.dart';
import '../models.dart';

class FixtureScreen extends StatelessWidget {
  final String torneoId;
  const FixtureScreen({super.key, required this.torneoId});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final t = store.porId(torneoId)!;
    // asegurar fixture
    if (t.fixture.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rol de juegos')),
        body: const Center(child: Text('Agrega al menos 2 equipos.')),
      );
    }
    final v1 = t.fixture.where((m) => m.vuelta == 1).toList();
    final v2 = t.fixture.where((m) => m.vuelta != 1 && t.sistema == Sistema.roundRobin2).toList();
    final esRR2 = t.sistema == Sistema.roundRobin2;

    Widget lista(List<Match> partidos, String titulo) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(titulo,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold))),
          ...partidos.map((m) => _tile(context, store, t, m)),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Rol de juegos')),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          if (esRR2) ...[
            lista(v1, 'Primera vuelta'),
            lista(v2, 'Segunda vuelta'),
            ..._extras(t, context, store),
          ] else if (t.sistema == Sistema.eliminacionDirecta) ...[
            ..._porRonda(t, context, store),
          ] else ...[
            lista(v1, 'Partidos generados'),
          ],
        ],
      ),
    );
  }

  List<Widget> _extras(Tournament t, BuildContext c, AppStore s) {
    final extras = t.fixture.where((m) => m.etiqueta == 'Extra').toList();
    if (extras.isEmpty) return [];
    return [
      const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('Agregados extra',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
      ...extras.map((m) => _tile(c, s, t, m)),
    ];
  }

  List<Widget> _porRonda(Tournament t, BuildContext c, AppStore s) {
    final rondas = <int>{...t.fixture.map((e) => e.vuelta)}.toList()..sort();
    return [
      for (final r in rondas)
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                    t.fixture.firstWhere((m) => m.vuelta == r).etiqueta.isEmpty
                        ? 'Ronda $r'
                        : t.fixture.firstWhere((m) => m.vuelta == r).etiqueta,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold))),
            ...t.fixture.where((m) => m.vuelta == r).map((m) => _tile(c, s, t, m)),
          ],
        )
    ];
  }

  Widget _tile(BuildContext context, AppStore store, Tournament t, Match m) {
    final jugado =
        t.resultados.any((r) => r.matchId == m.id);
    return Card(
      color: jugado ? Colors.green.shade50 : null,
      child: ListTile(
        title: Text(
            '${t.nombreEquipo(m.equipoAId)} vs ${t.nombreEquipo(m.equipoBId)}${m.etiqueta.isNotEmpty && m.etiqueta != 'Extra' ? ' (${m.etiqueta})' : ''}'),
        subtitle: Text(jugado ? 'Jugado' : (m.programado ? 'En jornada actual' : 'Sin programar')),
        trailing: Switch(
          value: m.programado && !jugado,
          activeColor: Colors.green,
          inactiveThumbColor: Colors.grey,
          onChanged: jugado
              ? null
              : (v) {
                  m.programado = v;
                  store.persistir();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(v
                          ? 'Enviado a Jornada actual (encendido)'
                          : 'Quitado de Jornada actual (apagado)')));
                },
        ),
      ),
    );
  }
}
