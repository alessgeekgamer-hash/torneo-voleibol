import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../store.dart';
import '../models.dart';
import '../theme.dart';
import 'tournament_form.dart';
import 'dashboard.dart';
import 'server_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return Scaffold(
      body: AppBg(
        child: Column(
          children: [
            const VoleyHeader(
            title: 'Volleyball\nTournament Control',
            subtitle: 'Rol • Jornada en vivo • Stats • PDF',
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: GradientButton(
                    icon: Icons.add_circle,
                    label: 'Nuevo torneo',
                    subtitle: 'Nombre • formato • sistema',
                    gradient: const [Color(0xFF00BFA6), Color(0xFF2979FF)],
                    onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                                const TournamentFormScreen())),
                  ),
                ),
                const SizedBox(width: 10),
                _ThemeBtn(),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            child: GradientButton(
              icon: Icons.vpn_lock,
              label: 'Ver en red',
              subtitle: 'Descargar torneo de otro equipo • Tailscale',
              gradient: const [Color(0xFF0B1E3B), Color(0xFF00BFA6)],
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ServerScreen())),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 8, 18, 6),
            child: Row(
              children: [
                const Icon(Icons.emoji_events,
                    color: VoleyColors.orange, size: 20),
                const SizedBox(width: 6),
                const Text('Continuar torneo',
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: VoleyColors.navy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${store.torneos.length} guardados',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          Expanded(
            child: store.torneos.isEmpty
                ? _vacio()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                    itemCount: store.torneos.length,
                    itemBuilder: (c, i) {
                      final t = store.torneos[i];
                      final grad = _grad(i);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: grad.last.withValues(alpha: 0.25),
                              blurRadius: 10,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Card(
                          margin: EdgeInsets.zero,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(20),
                            onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => DashboardScreen(
                                        torneoId: t.id))),
                            onLongPress: () =>
                                _confirmDelete(context, store, t),
                            child: Row(
                              children: [
                                Container(
                                  width: 8,
                                  height: 86,
                                  decoration: BoxDecoration(
                                    gradient:
                                        LinearGradient(colors: grad),
                                    borderRadius:
                                        const BorderRadius.horizontal(
                                            left: Radius.circular(20)),
                                  ),
                                ),
                                Container(
                                  margin: const EdgeInsets.all(12),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    gradient:
                                        LinearGradient(colors: grad),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Text('🏐',
                                      style: TextStyle(fontSize: 24)),
                                ),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(t.nombre,
                                          style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight:
                                                  FontWeight.bold)),
                                      const SizedBox(height: 4),
                                      Text(formatoLabel(t.formato),
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                      Text(
                                          '${sistemaLabel(t.sistema)} • ${t.equipos.length} equipos • ${t.resultados.length} jugados',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey)),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete,
                                      color: Colors.red),
                                  onPressed: () => _confirmDelete(
                                      context, store, t),
                                ),
                                const Icon(Icons.play_circle_fill,
                                    color: VoleyColors.teal, size: 30),
                                const SizedBox(width: 12),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Padding(
            padding: EdgeInsets.only(bottom: 6),
            child: Text('Versión $kAppVersion',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
        ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: VoleyColors.orange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.sports_volleyball),
        label: const Text('Jugar'),
        onPressed: store.torneos.isEmpty
            ? null
            : () {
                final t = store.torneos.last;
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            DashboardScreen(torneoId: t.id)));
              },
      ),
    );
  }

  List<Color> _grad(int i) {
    const sets = [
      [Color(0xFF00BFA6), Color(0xFF2979FF)],
      [Color(0xFFFF6F00), Color(0xFFFFC107)],
      [Color(0xFF7C4DFF), Color(0xFFFF4081)],
      [Color(0xFF00E676), Color(0xFF00BFA6)],
    ];
    return sets[i % sets.length];
  }

  Widget _vacio() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('🏐', style: TextStyle(fontSize: 64)),
          SizedBox(height: 8),
          Text('Sin torneos todavía',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Text('Toca “Nuevo torneo” para empezar el show',
              style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, AppStore store, Tournament t) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('🗑️ Borrar torneo'),
        content: Text('¿Eliminar "${t.nombre}" para siempre?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white),
            onPressed: () {
              store.eliminarTorneo(t.id);
              Navigator.pop(context);
            },
            child: const Text('Borrar'),
          ),
        ],
      ),
    );
  }
}

class _ThemeBtn extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return GestureDetector(
      onTap: () => store.toggleOscuro(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: store.oscuro
              ? [VoleyColors.yellow, VoleyColors.orange]
              : [VoleyColors.navy, VoleyColors.violet]),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Icon(
            store.oscuro ? Icons.light_mode : Icons.dark_mode,
            color: Colors.white,
            size: 28),
      ),
    );
  }
}
