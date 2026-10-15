import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../store.dart';
import '../logic_pdf.dart';
import '../theme.dart';

class StatsScreen extends StatelessWidget {
  final String torneoId;
  const StatsScreen({super.key, required this.torneoId});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final t = store.porId(torneoId)!;
    final stats = store.estadisticas(t);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas'),
        actions: [
          IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () => exportarEstadisticas(t, stats))
        ],
      ),
      body: AppBg(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
          columns: const [
            DataColumn(label: Text('Equipo')),
            DataColumn(label: Text('PJ')),
            DataColumn(label: Text('PG')),
            DataColumn(label: Text('PP')),
            DataColumn(label: Text('SF')),
            DataColumn(label: Text('SC')),
            DataColumn(label: Text('DifS')),
            DataColumn(label: Text('PF')),
            DataColumn(label: Text('PC')),
            DataColumn(label: Text('DifP')),
          ],
          rows: stats
              .map((s) => DataRow(cells: [
                    DataCell(Text(t.nombreEquipo(s.equipoId))),
                    DataCell(Text('${s.pj}')),
                    DataCell(Text('${s.pg}')),
                    DataCell(Text('${s.pp}')),
                    DataCell(Text('${s.sf}')),
                    DataCell(Text('${s.sc}')),
                    DataCell(Text('${s.difSets}')),
                    DataCell(Text('${s.pf}')),
                    DataCell(Text('${s.pc}')),
                    DataCell(Text('${s.difPuntos}')),
                  ]))
              .toList(),
        ),
        ),
      ),
    );
  }
}

class StandingsScreen extends StatelessWidget {
  final String torneoId;
  const StandingsScreen({super.key, required this.torneoId});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final t = store.porId(torneoId)!;
    final pos = store.posiciones(t);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Posiciones'),
        actions: [
          IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () => exportarPosiciones(t, pos))
        ],
      ),
      body: AppBg(
        child: ListView.builder(
          itemCount: pos.length,
          itemBuilder: (c, i) {
            final s = pos[i];
            return ListTile(
              leading: CircleAvatar(child: Text('${i + 1}')),
              title: Text(
                t.nombreEquipo(s.equipoId),
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                'PG:${s.pg}  PP:${s.pp}  PJ:${s.pj}\nSets ${s.sf}-${s.sc} (Dif ${s.difSets})  •  Pts ${s.pf}-${s.pc} (Dif ${s.difPuntos})',
                style: const TextStyle(fontSize: 12),
              ),
              isThreeLine: true,
            );
          },
        ),
      ),
    );
  }
}

class HistoryScreen extends StatelessWidget {
  final String torneoId;
  const HistoryScreen({super.key, required this.torneoId});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final t = store.porId(torneoId)!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de resultados'),
        actions: [
          IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              onPressed: () => exportarHistorial(t))
        ],
      ),
      body: AppBg(
        child: t.resultados.isEmpty
            ? const Center(child: Text('Sin partidos jugados.'))
            : ListView.builder(
                itemCount: t.resultados.length,
                itemBuilder: (c, i) {
                  final r = t.resultados[i];
                  return Card(
                    child: ListTile(
                      title: Text(
                          '${t.nombreEquipo(r.equipoAId)} ${r.setsA} - ${r.setsB} ${t.nombreEquipo(r.equipoBId)}'),
                      subtitle: Text(
                          'Ganador: ${t.nombreEquipo(r.ganadorId)}\nFecha: ${r.fecha.isEmpty ? '-' : r.fecha} • Lugar: ${r.lugar.isEmpty ? '-' : r.lugar}\nParciales: ${r.parciales.join(', ')}${r.sanciones.isNotEmpty ? '\nSanciones: ${r.sanciones.map((s) => s.tipo).join(', ')}' : ''}'),
                      trailing: IconButton(
                        tooltip: 'Exportar PDF del partido',
                        icon: const Icon(Icons.picture_as_pdf),
                        onPressed: () => exportarHojaPartido(t, r),
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
