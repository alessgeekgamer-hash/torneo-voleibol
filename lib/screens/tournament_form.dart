import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models.dart';
import '../store.dart';
import 'teams_screen.dart';

class TournamentFormScreen extends StatefulWidget {
  const TournamentFormScreen({super.key});
  @override
  State<TournamentFormScreen> createState() => _State();
}

class _State extends State<TournamentFormScreen> {
  final _nombre = TextEditingController();
  Formato _formato = Formato.dosDeTres;
  Sistema _sistema = Sistema.roundRobin1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agregar torneo')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _nombre,
              decoration: const InputDecoration(
                  labelText: 'Nombre del torneo',
                  border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            const Align(
                alignment: Alignment.centerLeft,
                child: Text('Formato del torneo:',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            RadioListTile<Formato>(
              title: const Text('Ganar 2 de 3 sets'),
              value: Formato.dosDeTres,
              groupValue: _formato,
              onChanged: (v) => setState(() => _formato = v!),
            ),
            RadioListTile<Formato>(
              title: const Text('Ganar 3 de 5 sets'),
              value: Formato.tresDeCinco,
              groupValue: _formato,
              onChanged: (v) => setState(() => _formato = v!),
            ),
            const Align(
                alignment: Alignment.centerLeft,
                child: Text('Sistema de eliminación:',
                    style: TextStyle(fontWeight: FontWeight.bold))),
            RadioListTile<Sistema>(
              title: const Text('Round Robin 1 vuelta'),
              value: Sistema.roundRobin1,
              groupValue: _sistema,
              onChanged: (v) => setState(() => _sistema = v!),
            ),
            RadioListTile<Sistema>(
              title: const Text('Round Robin 2 vueltas'),
              value: Sistema.roundRobin2,
              groupValue: _sistema,
              onChanged: (v) => setState(() => _sistema = v!),
            ),
            RadioListTile<Sistema>(
              title: const Text('Eliminación directa'),
              value: Sistema.eliminacionDirecta,
              groupValue: _sistema,
              onChanged: (v) => setState(() => _sistema = v!),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                child: const Text('Guardar y agregar equipos'),
                onPressed: () async {
                  if (_nombre.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Escribe el nombre del torneo')));
                    return;
                  }
                  final t = Tournament(
                      nombre: _nombre.text.trim(),
                      formato: _formato,
                      sistema: _sistema);
                  await context.read<AppStore>().agregarTorneo(t);
                  if (!context.mounted) return;
                  Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              TeamsScreen(torneoId: t.id, esNuevo: true)));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
