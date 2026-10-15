import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'roster_screen.dart';
import 'live_game_screen.dart';
import 'lineup_screen.dart';

class JornadaScreen extends StatelessWidget {
  final String torneoId;
  const JornadaScreen({super.key, required this.torneoId});

  void _preguntarContinuar(
      BuildContext context, AppStore store, PausaPartido pausa) {
    final t = store.porId(torneoId)!;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Continuar encuentro'),
        content: Text(
            '${t.nombreEquipo(pausa.ladoAId)} vs ${t.nombreEquipo(pausa.ladoBId)}\n'
            'Suspendido en set ${pausa.setNumero} (${pausa.pA}-${pausa.pB}).\n\n'
            '¿Seguir con las mismas posiciones o editar la alineación para lo que resta del set?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          LiveGameScreen.desdePausa(pausa: pausa)));
            },
            child: const Text('Seguir igual'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => LineupScreen(
                            torneoId: pausa.torneoId,
                            matchId: pausa.matchId,
                            ladoAId: pausa.ladoAId,
                            ladoBId: pausa.ladoBId,
                            saqueId: pausa.sacaId,
                            setNumero: pausa.setNumero,
                            pausa: pausa,
                          )));
            },
            child: const Text('Editar posiciones'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final t = store.porId(torneoId)!;
    // (4) los jugados desaparecen: solo programados sin resultado
    final partidos = t.fixture
        .where((m) =>
            m.programado && !t.resultados.any((r) => r.matchId == m.id))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Jornada actual')),
      body: AppBg(
        child: partidos.isEmpty
            ? const Center(
                child: Text(
                    'No hay partidos programados.\nActívalos en Rol de juegos.',
                    textAlign: TextAlign.center))
            : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: partidos.length,
              itemBuilder: (c, i) {
                final m = partidos[i];
                final pausa = store.pausaDe(torneoId, m.id);
                return Card(
                  child: ListTile(
                    title: Text(
                        '${t.nombreEquipo(m.equipoAId)} vs ${t.nombreEquipo(m.equipoBId)}',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                        '${m.etiqueta}${m.fecha.isNotEmpty ? '\nFecha: ${m.fecha}' : ''}${m.lugar.isNotEmpty ? '\nLugar: ${m.lugar}' : ''}${pausa != null ? '\nSuspendido en set ${pausa.setNumero} (${pausa.pA}-${pausa.pB})' : ''}'),
                    isThreeLine: true,
                    trailing: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton(
                          child: const Text('Iniciar encuentro'),
                          onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => RosterScreen(
                                      torneoId: torneoId,
                                      matchId: m.id))),
                        ),
                        if (pausa != null)
                          TextButton(
                            child: const Text('Continuar encuentro'),
                            onPressed: () => _preguntarContinuar(
                                context, store, pausa),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
      ),
    );
  }
}
