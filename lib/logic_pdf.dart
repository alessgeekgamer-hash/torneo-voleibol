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
              pw.Text(
                  'Fecha: ${r.fecha.isEmpty ? '-' : r.fecha} • Lugar: ${r.lugar.isEmpty ? '-' : r.lugar}'),
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

/// (11) Hoja detallada por partido: fecha, lugar, partido, ganador,
/// sets/puntos, tiempos y cambios por set y totales, rosters y sanciones.
Future<void> exportarHojaPartido(Tournament t, MatchResult r) async {
  final nomA = t.nombreEquipo(r.equipoAId);
  final nomB = t.nombreEquipo(r.equipoBId);
  final doc = pw.Document();

  int numSets = r.parciales.length;
  int at(int i, List<int> l) => i < l.length ? l[i] : 0;
  int ptsA(int i) {
    final p = r.parciales[i].split('-');
    return int.tryParse(p[0].trim()) ?? 0;
  }

  int ptsB(int i) {
    final p = r.parciales[i].split('-');
    return p.length > 1 ? int.tryParse(p[1].trim()) ?? 0 : 0;
  }

  int totTA = r.totalTiemposA,
      totTB = r.totalTiemposB,
      totCA = r.totalCambiosA,
      totCB = r.totalCambiosB;
  int totPA = 0, totPB = 0;
  for (var i = 0; i < numSets; i++) {
    totPA += ptsA(i);
    totPB += ptsB(i);
  }

  doc.addPage(pw.MultiPage(
    build: (c) => [
      pw.Center(
          child: pw.Text('HOJA DE RESULTADO - $nomA vs $nomB',
              style: pw.TextStyle(
                  fontSize: 20, fontWeight: pw.FontWeight.bold))),
      pw.SizedBox(height: 8),
      pw.Text('Torneo: ${t.nombre}',
          style: const pw.TextStyle(fontSize: 14)),
      pw.Text(
          'Partido: $nomA vs $nomB  •  Ganador: ${t.nombreEquipo(r.ganadorId)} (${r.setsA}-${r.setsB})'),
      pw.Text(
          'Fecha: ${r.fecha.isEmpty ? '-' : r.fecha}   •   Lugar: ${r.lugar.isEmpty ? '-' : r.lugar}'),
      pw.SizedBox(height: 10),
      pw.Text('Resumen por set',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      pw.TableHelper.fromTextArray(
        headers: [
          'Set',
          'Tiempos $nomA',
          'Cambios $nomA',
          'Pts $nomA',
          'Pts $nomB',
          'Ganó set',
          'Cambios $nomB',
          'Tiempos $nomB',
        ],
        data: [
          for (var i = 0; i < numSets; i++)
            [
              'Set ${i + 1}',
              '${at(i, r.tiemposA)}',
              '${at(i, r.cambiosA)}',
              '${ptsA(i)}',
              '${ptsB(i)}',
              ptsA(i) > ptsB(i) ? nomA : nomB,
              '${at(i, r.cambiosB)}',
              '${at(i, r.tiemposB)}',
            ],
          [
            'TOTAL',
            '$totTA',
            '$totCA',
            '$totPA',
            '$totPB',
            '${r.setsA}-${r.setsB}',
            '$totCB',
            '$totTB',
          ],
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(nomA,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold)),
                  ...r.jugadoresA.map((j) =>
                      pw.Text('#${j.numero ?? '-'} ${j.nombre}')),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Container(
              padding: const pw.EdgeInsets.all(8),
              decoration: pw.BoxDecoration(border: pw.Border.all()),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(nomB,
                      style: pw.TextStyle(
                          fontWeight: pw.FontWeight.bold)),
                  ...r.jugadoresB.map((j) =>
                      pw.Text('#${j.numero ?? '-'} ${j.nombre}')),
                ],
              ),
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 10),
      pw.Text('Sanciones',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
      if (r.sanciones.isEmpty)
        pw.Text('Sin sanciones registradas.')
      else
        pw.TableHelper.fromTextArray(
          headers: ['Sanción', 'Equipo', 'Set', 'Marcador'],
          data: r.sanciones
              .map((s) => [
                    s.tipo,
                    t.nombreEquipo(s.equipoId) +
                        (s.grupal
                            ? ' (Equipo)'
                            : ' #${s.jugadorNumero ?? '-'} ${s.jugadorNombre ?? ''}'),
                    'Set ${s.set}',
                    '${s.marcadorA}-${s.marcadorB}',
                  ])
              .toList(),
        ),
    ],
  ));
  await Printing.layoutPdf(onLayout: (f) async => doc.save());
}
