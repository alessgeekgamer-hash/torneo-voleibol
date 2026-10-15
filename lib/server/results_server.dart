import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import '../models.dart';
import '../store.dart';

/// Servidor HTTP local de solo lectura para consultar resultados
/// desde otros dispositivos de la misma red (ideal con Tailscale:
/// todos los dispositivos en la misma Tailnet abren
/// http://IP-TAILSCALE:8080 en su navegador).
class ResultsServer extends ChangeNotifier {
  static final ResultsServer instance = ResultsServer._();
  ResultsServer._();

  HttpServer? _server;
  int port = 8080;
  String? error;

  bool get running => _server != null;
  int get activePort => _server?.port ?? port;

  Future<List<String>> ips() async {
    final out = <String>[];
    try {
      for (final i in await NetworkInterface.list()) {
        for (final a in i.addresses) {
          if (a.type == InternetAddressType.IPv4 && !a.isLoopback) {
            out.add(a.address);
          }
        }
      }
    } catch (_) {}
    // La IP 100.x.y.z de Tailscale aparece aquí cuando está activo.
    out.sort((a, b) =>
        (a.startsWith('100.') ? 0 : 1).compareTo(
            b.startsWith('100.') ? 0 : 1));
    return out;
  }

  Future<bool> start(AppStore store, {int? port}) async {
    if (running) return true;
    try {
      if (port != null) this.port = port;
      _server =
          await shelf_io.serve(_handler(store), InternetAddress.anyIPv4, this.port);
      error = null;
      notifyListeners();
      return true;
    } catch (e) {
      error = '$e';
      notifyListeners();
      return false;
    }
  }

  Future<void> stop() async {
    await _server?.close(force: true);
    _server = null;
    notifyListeners();
  }

  Handler _handler(AppStore store) {
    return (Request req) async {
      try {
        final segs = req.url.pathSegments;
        if (req.method == 'POST' &&
            segs.length == 2 &&
            segs[0] == 'api' &&
            segs[1] == 'sync') {
          return _sync(store, await req.readAsString());
        }
        if (segs.isEmpty) return _html(_indexHtml(store));
        if (segs.length == 1 && segs[0] == 'api') {
          return _html(_indexHtml(store));
        }
        if (segs.length == 2 &&
            segs[0] == 'api' &&
            segs[1] == 'torneos') {
          return Response.ok(jsonEncode(_json(store)),
              headers: {'content-type': 'application/json; charset=utf-8'});
        }
        if (segs.length == 2 && segs[0] == 'torneo') {
          final t = store.porId(segs[1]);
          if (t == null) return Response.notFound('Torneo no encontrado');
          return _html(_torneoHtml(store, t.id));
        }
        return Response.notFound('No encontrado');
      } catch (e) {
        return Response.internalServerError(body: 'Error: $e');
      }
    };
  }

  /// Recibe torneos de otro dispositivo y los fusiona (para llevar el
  /// control en dos equipos a la vez: cada uno registra partidos
  /// distintos y al sincronizar se unen sin duplicar).
  Future<Response> _sync(AppStore store, String body) async {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      final lista = (data['torneos'] ?? []) as List;
      var equipos = 0, resultados = 0, torneos = 0;
      for (final raw in lista) {
        final remoto =
            Tournament.fromJson(Map<String, dynamic>.from(raw));
        final r = store.fusionarTorneo(remoto);
        torneos++;
        equipos += r['equipos'] as int;
        resultados += r['resultados'] as int;
      }
      await store.persistir();
      return Response.ok(
          jsonEncode({
            'ok': true,
            'torneos': torneos,
            'equiposNuevos': equipos,
            'resultadosNuevos': resultados,
          }),
          headers: {'content-type': 'application/json; charset=utf-8'});
    } catch (e) {
      return Response.internalServerError(
          body: jsonEncode({'ok': false, 'error': '$e'}),
          headers: {'content-type': 'application/json; charset=utf-8'});
    }
  }

  Response _html(String body) => Response.ok(body,
      headers: {'content-type': 'text/html; charset=utf-8'});

  Map<String, dynamic> _json(AppStore store) => {
        'torneos': store.torneos
            .map((t) => {
                  'id': t.id,
                  'nombre': t.nombre,
                  'formato': formatoLabel(t.formato),
                  'sistema': sistemaLabel(t.sistema),
                  'equipos': t.equipos
                      .map((e) =>
                          {'id': e.id, 'nombre': e.nombre, 'baja': t.estaDeBaja(e.id)})
                      .toList(),
                  'resultados': t.resultados.map((r) => r.toJson()).toList(),
                  'posiciones': store
                      .posiciones(t)
                      .map((s) => {
                            'equipo': t.nombreEquipo(s.equipoId),
                            'pj': s.pj,
                            'pg': s.pg,
                            'pp': s.pp,
                            'sf': s.sf,
                            'sc': s.sc,
                            'pf': s.pf,
                            'pc': s.pc,
                          })
                      .toList(),
                })
            .toList(),
      };

}

String _esc(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _page(String titulo, String cuerpo) => '''
<!DOCTYPE html><html lang="es"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="refresh" content="20">
<title>${_esc(titulo)}</title>
<style>
body{font-family:system-ui,Arial,sans-serif;margin:0;background:#0B1E3B;color:#fff;padding:16px}
a{color:#FFC107}.card{background:#fff;color:#111;border-radius:12px;padding:12px;margin:12px 0}
table{width:100%;border-collapse:collapse;font-size:14px}
th,td{border:1px solid #999;padding:6px;text-align:center}
th{background:#00BFA6;color:#fff}h1{font-size:22px}.mut{color:#666;font-size:12px}
.badge{display:inline-block;background:#FFC107;color:#111;border-radius:12px;padding:2px 10px;font-weight:bold;font-size:12px}
</style></head><body>
<h1>🏐 ${_esc(titulo)}</h1>
$cuerpo
<p class="mut">Volleyball Tournament Control • se actualiza solo cada 20 s</p>
</body></html>''';

String _indexHtml(AppStore store) {
  final b = StringBuffer();
  if (store.torneos.isEmpty) {
    b.write('<div class="card">Sin torneos todavía.</div>');
  }
  for (final t in store.torneos) {
    b.write('<div class="card"><h2>${_esc(t.nombre)}</h2>'
        '<p>${t.equipos.length} equipos • ${t.resultados.length} partidos jugados</p>'
        '<p><a href="/torneo/${t.id}">Ver posiciones y resultados →</a></p></div>');
  }
  return _page('Torneos', b.toString());
}

String _torneoHtml(AppStore store, String id) {
  final t = store.porId(id)!;
  final pos = store.posiciones(t);
  final b = StringBuffer();
  b.write('<p><a href="/">← Todos los torneos</a></p>');
  b.write('<div class="card"><h2>${_esc(t.nombre)} '
      '<span class="badge">${t.resultados.length} jugados</span></h2>');
  b.write('<table><tr><th>#</th><th>Equipo</th><th>PJ</th><th>PG</th>'
      '<th>PP</th><th>SF-SC</th><th>PF-PC</th></tr>');
  for (var i = 0; i < pos.length; i++) {
    final s = pos[i];
    b.write('<tr><td>${i + 1}</td><td>${_esc(t.nombreEquipo(s.equipoId))}</td>'
        '<td>${s.pj}</td><td>${s.pg}</td><td>${s.pp}</td>'
        '<td>${s.sf}-${s.sc}</td><td>${s.pf}-${s.pc}</td></tr>');
  }
  b.write('</table></div>');
  b.write('<div class="card"><h2>Resultados</h2>');
  if (t.resultados.isEmpty) {
    b.write('<p>Sin partidos jugados.</p>');
  }
  for (final r in t.resultados) {
    b.write('<p><b>${_esc(t.nombreEquipo(r.equipoAId))} ${r.setsA} - '
        '${r.setsB} ${_esc(t.nombreEquipo(r.equipoBId))}</b><br>'
        'Ganador: ${_esc(t.nombreEquipo(r.ganadorId))} • '
        'Parciales: ${_esc(r.parciales.join(', '))}'
        '${r.lugar.isNotEmpty ? ' • ${_esc(r.lugar)}' : ''}</p>');
  }
  b.write('</div>');
  return _page(t.nombre, b.toString());
}
