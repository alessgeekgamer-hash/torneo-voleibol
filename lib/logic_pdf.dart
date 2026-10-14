import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models.dart';
import '../store.dart';

Future<void> exportarEstadisticas(
    Tournament t, List<StatRow> stats) async {
  final doc = pw.Document();
  doc.addPage(pw.MultiPage(
    build: (c) => [
      pw.Header(level: 0, text: 'Estadísticas - ${t.nombre}'),
      pw.TableHelper.fromTextArray(
        headers: ['Equipo', 'PJ', 'PG', 'PP', 'SF', 'SC', 'DifS', 'PF', 'PC', 'DifP'],
        data: stats
            .map((s) => [
                  t.nombreEquipo(s.equipoId),
                  '${s.pj}',
                  '${s.pg}',
                  '${s.pp}',
                  '${s.sf}',
                  '${s.sc}',
                  '${s.difSets}',
                  '${s.pf}',
                  '${s.pc}',
                  '${s.difPuntos}',
                ])
            .toList(),
      ),
    ],
  ));
  await Printing.layoutPdf(onLayout: (f) async => doc.save());
}

Future<void> exportarPosiciones(Tournament t, List<StatRow> pos) async {
  final doc = pw.Document();
  doc.addPage(pw.MultiPage(
    build: (c) => [
      pw.Header(level: 0, text: 'Posiciones - ${t.nombre}'),
      pw.TableHelper.fromTextArray(
        headers: ['Pos', 'Equipo', 'PG', 'Dif Sets', 'Dif Pts'],
        data: [
          for (var i = 0; i < pos.length; i++)
            [
              '${i + 1}',
              t.nombreEquipo(pos[i].equipoId),
              '${pos[i].pg}',
              '${pos[i].difSets}',
              '${pos[i].difPuntos}',
            ]
        ],
      ),
    ],
  ));
  await Printing.layoutPdf(onLayout: (f) async => doc.save());
}

Future<void> exportarHistorial(Tournament t) async {
  final doc = pw.Document();
  doc.addPage(pw.MultiPage(
    build: (c) => [
      pw.Header(level: 0, text: 'Historial - ${t.nombre}'),
      ...t.resultados.map((r) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                  '${t.nombreEquipo(r.equipoAId)} ${r.setsA} - ${r.setsB} ${t.nombreEquipo(r.equipoBId)}  Ganador: ${t.nombreEquipo(r.ganadorId)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.Text('Parciales: ${r.parciales.join(', ')}'),
              if (r.sanciones.isNotEmpty)
                pw.Text(
                    'Sanciones: ${r.sanciones.map((s) => '${s.tipo} (${t.nombreEquipo(s.equipoId)} S${s.set} ${s.marcadorA}-${s.marcadorB})').join('; ')}'),
              pw.SizedBox(height: 8),
            ],
          )),
    ],
  ));
  await Printing.layoutPdf(onLayout: (f) async => doc.save());
}

Future<void> exportarHojaPartido(Tournament t, MatchResult r) async {
  final doc = pw.Document();
  doc.addPage(pw.MultiPage(
    build: (c) => [
      pw.Center(
          child: pw.Text('HOJA DE RESULTADO',
              style: pw.TextStyle(
                  fontSize: 22, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 12),
      pw.Text('Torneo: ${t.nombre}', style: const pw.TextStyle(fontSize: 16)),
      pw.Text(
          '${t.nombreEquipo(r.equipoAId)} ${r.setsA} - ${r.setsB} ${t.nombreEquipo(r.equipoBId)}'),
      pw.Text('Ganador: ${t.nombreEquipo(r.ganadorId)}',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.Text('Parciales: ${r.parciales.join(', ')}'),
      pw.SizedBox(height: 8),
      pw.Text('Jugadores ${t.nombreEquipo(r.equipoAId)}:',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ...r.jugadoresA.map((j) => pw.Text('#${j.numero ?? '-'} ${j.nombre}')),
      pw.SizedBox(height: 6),
      pw.Text('Jugadores ${t.nombreEquipo(r.equipoBId)}:',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ...r.jugadoresB.map((j) => pw.Text('#${j.numero ?? '-'} ${j.nombre}')),
      pw.SizedBox(height: 6),
      pw.Text('Sanciones:',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      ...r.sanciones.map((s) => pw.Text(
          '${s.tipo} - ${t.nombreEquipo(s.equipoId)} ${s.grupal ? '(Equipo)' : '#${s.jugadorNumero ?? '-'} ${s.jugadorNombre ?? ''}'} Set ${s.set} (${s.marcadorA}-${s.marcadorB})')),
    ],
  ));
  await Printing.layoutPdf(onLayout: (f) async => doc.save());
}
