import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../models.dart';
import '../store.dart';
import 'dashboard.dart';

class TeamsScreen extends StatelessWidget {
  final String torneoId;
  final bool esNuevo;
  const TeamsScreen(
      {super.key, required this.torneoId, this.esNuevo = false});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final t = store.porId(torneoId);
    if (t == null) return const Scaffold(body: Center(child: Text('Torneo no encontrado')));
    return Scaffold(
      appBar: AppBar(title: Text('Equipos - ${t.nombre}')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _AgregarEquipo(torneoId: torneoId),
            const SizedBox(height: 12),
            Expanded(
              child: ListView.builder(
                itemCount: t.equipos.length,
                itemBuilder: (c, i) {
                  final eq = t.equipos[i];
                  return Card(
                    child: ListTile(
                      title: Text('${eq.nombre} (${eq.jugadores.length} jugadores)'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Editar',
                            icon: const Icon(Icons.edit),
                            onPressed: () => _editarEquipo(context, store, t, eq),
                          ),
                          IconButton(
                            tooltip: 'Borrar',
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              t.equipos.removeWhere((e) => e.id == eq.id);
                              t.fixture.removeWhere((m) =>
                                  m.equipoAId == eq.id ||
                                  m.equipoBId == eq.id);
                              store.persistir();
                            },
                          ),
                          TextButton(
                            child: const Text('Cédula'),
                            onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => CedulaScreen(
                                        torneoId: torneoId,
                                        equipoId: eq.id))),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: t.equipos.length < 2
                    ? null
                    : () async {
                        await store.asegurarFixture(t);
                        await store.persistir();
                        if (!context.mounted) return;
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    DashboardScreen(torneoId: torneoId)),
                            (r) => r.isFirst);
                      },
                child: Text(esNuevo
                    ? 'Guardar y continuar al torneo'
                    : 'Volver'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _editarEquipo(
      BuildContext context, AppStore store, Tournament t, Team eq) {
    final c = TextEditingController(text: eq.nombre);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Editar equipo'),
        content: TextField(controller: c, decoration: const InputDecoration(labelText: 'Nombre del equipo')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
              onPressed: () {
                if (c.text.trim().isNotEmpty) {
                  eq.nombre = c.text.trim();
                  store.persistir();
                }
                Navigator.pop(context);
              },
              child: const Text('Guardar')),
        ],
      ),
    );
  }
}

class _AgregarEquipo extends StatefulWidget {
  final String torneoId;
  const _AgregarEquipo({required this.torneoId});
  @override
  State<_AgregarEquipo> createState() => _AState();
}

class _AState extends State<_AgregarEquipo> {
  final _c = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
            child: TextField(
                controller: _c,
                decoration: const InputDecoration(
                    labelText: 'Nombre del equipo',
                    border: OutlineInputBorder()))),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () {
            if (_c.text.trim().isEmpty) return;
            final store = context.read<AppStore>();
            final t = store.porId(widget.torneoId)!;
            t.equipos.add(Team(nombre: _c.text.trim()));
            _c.clear();
            store.persistir();
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

class CedulaScreen extends StatelessWidget {
  final String torneoId;
  final String equipoId;
  const CedulaScreen(
      {super.key, required this.torneoId, required this.equipoId});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final t = store.porId(torneoId)!;
    final eq = t.equipoPorId(equipoId)!;
    return Scaffold(
      appBar: AppBar(title: Text('Cédula - ${eq.nombre}')),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.person_add),
        onPressed: () => _dialogoJugador(context, store, eq, null),
      ),
      body: ListView.builder(
        itemCount: eq.jugadores.length,
        itemBuilder: (c, i) {
          final j = eq.jugadores[i];
          return Card(
            child: ListTile(
              leading: _avatar(j),
              title: Text(j.nombreCompleto.isEmpty ? '(sin nombre)' : j.nombreCompleto),
              subtitle: Text(
                  'Nac: ${j.fechaNacimiento.isEmpty ? '-' : j.fechaNacimiento} • Tel: ${j.telefono.isEmpty ? '-' : j.telefono} • #${j.numero?.toString() ?? '-'}'),
              trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () =>
                        _dialogoJugador(context, store, eq, j)),
                IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      eq.jugadores.removeWhere((e) => e.id == j.id);
                      store.persistir();
                    }),
              ]),
            ),
          );
        },
      ),
    );
  }

  Widget _avatar(Player j) {
    if (j.fotoPath != null && File(j.fotoPath!).existsSync()) {
      return CircleAvatar(backgroundImage: FileImage(File(j.fotoPath!)));
    }
    return const CircleAvatar(child: Icon(Icons.person));
  }

  void _dialogoJugador(
      BuildContext context, AppStore store, Team eq, Player? existente) {
    final nombre = TextEditingController(text: existente?.nombre ?? '');
    final apellido = TextEditingController(text: existente?.apellido ?? '');
    final nac = TextEditingController(text: existente?.fechaNacimiento ?? '');
    final tel = TextEditingController(text: existente?.telefono ?? '');
    String? foto = existente?.fotoPath;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(builder: (c, setS) {
        return AlertDialog(
          title: Text(existente == null ? 'Nuevo jugador' : 'Editar jugador'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: () async {
                    final img = await ImagePicker()
                        .pickImage(source: ImageSource.gallery);
                    if (img != null) {
                      setS(() => foto = img.path);
                    }
                  },
                  child: foto != null && File(foto!).existsSync()
                      ? CircleAvatar(
                          radius: 36,
                          backgroundImage: FileImage(File(foto!)))
                      : const CircleAvatar(
                          radius: 36, child: Icon(Icons.camera_alt)),
                ),
                const SizedBox(height: 4),
                const Text('Foto (opcional)', style: TextStyle(fontSize: 12)),
                TextField(controller: nombre, decoration: const InputDecoration(labelText: 'Nombre *')),
                TextField(controller: apellido, decoration: const InputDecoration(labelText: 'Apellido')),
                TextField(controller: nac, decoration: const InputDecoration(labelText: 'Fecha de nacimiento')),
                TextField(controller: tel, decoration: const InputDecoration(labelText: 'Teléfono'), keyboardType: TextInputType.phone),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            TextButton(
              onPressed: () {
                if (nombre.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('El nombre es obligatorio')));
                  return;
                }
                if (existente == null) {
                  eq.jugadores.add(Player(
                      nombre: nombre.text.trim(),
                      apellido: apellido.text.trim(),
                      fechaNacimiento: nac.text.trim(),
                      telefono: tel.text.trim(),
                      fotoPath: foto));
                } else {
                  existente.nombre = nombre.text.trim();
                  existente.apellido = apellido.text.trim();
                  existente.fechaNacimiento = nac.text.trim();
                  existente.telefono = tel.text.trim();
                  existente.fotoPath = foto;
                }
                store.persistir();
                Navigator.pop(context);
              },
              child: const Text('Guardar y agregar otro'),
            ),
          ],
        );
      }),
    );
  }
}
