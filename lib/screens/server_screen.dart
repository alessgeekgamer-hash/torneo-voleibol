import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../server/results_server.dart';
import '../store.dart';
import '../theme.dart';

/// Pantalla para publicar los resultados en la red local / Tailscale
/// y consultarlos desde otros dispositivos con su navegador.
class ServerScreen extends StatefulWidget {
  const ServerScreen({super.key});
  @override
  State<ServerScreen> createState() => _State();
}

class _State extends State<ServerScreen> {
  List<String> _ips = [];
  final _port = TextEditingController(text: '8080');

  @override
  void initState() {
    super.initState();
    _cargarIps();
  }

  Future<void> _cargarIps() async {
    _ips = await ResultsServer.instance.ips();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return ListenableBuilder(
      listenable: ResultsServer.instance,
      builder: (c, _) {
        final srv = ResultsServer.instance;
        return Scaffold(
          appBar: AppBar(title: const Text('Ver en otros dispositivos')),
          body: AppBg(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text(
                      '1. Instala Tailscale en este equipo y en los otros dispositivos e inicia sesión con la misma cuenta.\n'
                      '2. Enciende el servidor aquí abajo.\n'
                      '3. En el otro dispositivo abre el navegador en http://TU-IP-TAILSCALE:8080 (la IP que empieza con 100.).\n'
                      'Funciona sin internet, solo la red Tailscale.'),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _port,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                          labelText: 'Puerto', border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: Icon(srv.running ? Icons.stop : Icons.play_arrow),
                    label: Text(srv.running ? 'Apagar' : 'Encender'),
                    onPressed: () async {
                      if (srv.running) {
                        await srv.stop();
                      } else {
                        final p = int.tryParse(_port.text.trim()) ?? 8080;
                        final ok = await srv.start(store, port: p);
                        if (!context.mounted) return;
                        if (!ok) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'No se pudo encender: ${srv.error}')));
                        }
                        _cargarIps();
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                  srv.running
                      ? 'Servidor encendido en puerto ${srv.activePort}'
                      : 'Servidor apagado',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: srv.running ? Colors.green : Colors.grey)),
              if (srv.error != null)
                Text(srv.error!,
                    style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 8),
              const Text('Direcciones de este equipo:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              ..._ips.map((ip) {
                final esTailscale = ip.startsWith('100.');
                final url = 'http://$ip:${srv.activePort}';
                return Card(
                  color: esTailscale ? Colors.green.shade50 : null,
                  child: ListTile(
                    leading: Icon(esTailscale
                        ? Icons.vpn_lock
                        : Icons.wifi),
                    title: Text(url,
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(esTailscale
                        ? 'IP de Tailscale — úsala en los otros dispositivos'
                        : 'Red local / WiFi'),
                    trailing: IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: url));
                        ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Dirección copiada')));
                      },
                    ),
                  ),
                );
              }),
              if (_ips.isEmpty)
                const Text(
                    'No se detectaron IPs. Revisa tu conexión o Tailscale.'),
              const SizedBox(height: 8),
              const Text(
                  'En Windows permite el puerto en el firewall la primera vez. '
                  'La página se actualiza sola cada 20 segundos.',
                  style: TextStyle(fontSize: 12, color: Colors.grey)),
            ],
          ),
        ),
        );
      },
    );
  }
}
