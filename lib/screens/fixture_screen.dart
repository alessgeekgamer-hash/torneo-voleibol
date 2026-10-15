import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../store.dart';
import '../models.dart';
import '../theme.dart';

class FixtureScreen extends StatefulWidget {
  final String torneoId;
  const FixtureScreen({super.key, required this.torneoId});

  @override
  State<FixtureScreen> createState() => _State();
}

class _State extends State<FixtureScreen> {
  String filtro = '';

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final t = store.porId(widget.torneoId)!;
    if (t.fixture.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Rol de juegos')),
        body: const Center(child: Text('Agrega al menos 2 equipos.')),
      );
    }
    bool coincide(Match m) {
      if (filtro.trim().isEmpty) return true;
      final q = filtro.toLowerCase();
      return t.nombreEquipo(m.equipoAId).toLowerCase().contains(q) ||
          t.nombreEquipo(m.equipoBId).toLowerCase().contains(q);
    }

    final v1 =
        t.fixture.where((m) => m.vuelta == 1 && coincide(m)).toList();
    final v2 = t.fixture
        .where((m) =>
            m.vuelta != 1 &&
            t.sistema == Sistema.roundRobin2 &&
            coincide(m))
        .toList();
    final esRR2 = t.sistema == Sistema.roundRobin2;

    Widget lista(List<Match> partidos, String titulo) {
      if (partidos.isEmpty) return const SizedBox();
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
      body: AppBg(
        child: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            TextField(
              decoration: const InputDecoration(
                labelText: 'Buscar partido por equipo',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => filtro = v),
            ),
            const SizedBox(height: 8),
            if (esRR2) ...[
              lista(v1, 'Primera vuelta'),
              lista(v2, 'Segunda vuelta'),
              ..._extras(t, context, store, coincide),
            ] else if (t.sistema == Sistema.eliminacionDirecta) ...[
              ..._porRonda(t, context, store, coincide),
            ] else ...[
              lista(v1, 'Partidos generados'),
            ],
          ],
        ),
      ),
    );
  }

  List<Widget> _extras(Tournament t, BuildContext c, AppStore s,
      bool Function(Match) coincide) {
    final extras = t.fixture
        .where((m) => m.etiqueta == 'Extra' && coincide(m))
        .toList();
    if (extras.isEmpty) return [];
    return [
      const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text('Agregados extra',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
      ...extras.map((m) => _tile(c, s, t, m)),
    ];
  }

  List<Widget> _porRonda(Tournament t, BuildContext c, AppStore s,
      bool Function(Match) coincide) {
    final rondas = <int>{...t.fixture.map((e) => e.vuelta)}.toList()
      ..sort();
    return [
      for (final r in rondas)
        Builder(builder: (_) {
          final parts =
              t.fixture.where((m) => m.vuelta == r && coincide(m)).toList();
          if (parts.isEmpty) return const SizedBox();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                      t.fixture
                              .firstWhere((m) => m.vuelta == r)
                              .etiqueta
                              .isEmpty
                          ? 'Ronda $r'
                          : t.fixture
                              .firstWhere((m) => m.vuelta == r)
                              .etiqueta,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold))),
              ...parts.map((m) => _tile(c, s, t, m)),
            ],
          );
        })
    ];
  }

  Widget _tile(
      BuildContext context, AppStore store, Tournament t, Match m) {
    MatchResult? res;
    try {
      res = t.resultados.firstWhere((r) => r.matchId == m.id);
    } catch (_) {
      res = null;
    }
    final r = res;
    final jugado = r != null;
    final seleccionado = m.programado && !jugado;
    final baja = t.estaDeBaja(m.equipoAId) || t.estaDeBaja(m.equipoBId);
    final sub = r != null
        ? 'TERMINADO: ${t.nombreEquipo(r.equipoAId)} ${r.setsA} - ${r.setsB} ${t.nombreEquipo(r.equipoBId)} (${r.parciales.join(', ')})'
        : (m.programado
            ? 'En jornada actual'
            : 'Sin programar${m.fecha.isNotEmpty ? ' • ${m.fecha}' : ''}${m.lugar.isNotEmpty ? ' • ${m.lugar}' : ''}');
    final tituloNegro = seleccionado || jugado;
    return Card(
      // (2) seleccionado: recuadro blanco con letras negras.
      // Terminado: fondo verde claro con letras negras para que se lea.
      color: seleccionado
          ? Colors.white
          : (jugado ? Colors.green.shade100 : null),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: seleccionado
            ? const BorderSide(color: Colors.black, width: 2)
            : BorderSide.none,
      ),
      child: ListTile(
        title: Text(
            '${t.nombreEquipo(m.equipoAId)} vs ${t.nombreEquipo(m.equipoBId)}${m.etiqueta.isNotEmpty && m.etiqueta != 'Extra' ? ' (${m.etiqueta})' : ''}${baja ? ' (BAJA)' : ''}',
            style: TextStyle(
                color: tituloNegro ? Colors.black : null,
                fontWeight:
                    tituloNegro ? FontWeight.bold : FontWeight.normal)),
        subtitle: Text(sub,
            style: TextStyle(
                color: tituloNegro ? Colors.black : null)),
        trailing: Switch(
          value: m.programado && !jugado,
          activeThumbColor: Colors.green,
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
