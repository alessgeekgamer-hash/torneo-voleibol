import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../store.dart';
import '../theme.dart';
import 'fixture_screen.dart';
import 'jornada_screen.dart';
import 'stats_screens.dart';
import 'edit_tournament_screen.dart';

class DashboardScreen extends StatelessWidget {
  final String torneoId;
  const DashboardScreen({super.key, required this.torneoId});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    final t = store.porId(torneoId);
    if (t == null) {
      return const Scaffold(body: Center(child: Text('Torneo no encontrado')));
    }
    final items = [
      _Item('Rol de juegos', 'Todos los partidos', Icons.list_alt,
          [VoleyColors.teal, VoleyColors.blue], () {
        store.asegurarFixture(t);
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => FixtureScreen(torneoId: torneoId)));
      }),
      _Item('Jornada actual', 'A jugar hoy', Icons.play_circle_fill,
          [VoleyColors.orange, VoleyColors.yellow], () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => JornadaScreen(torneoId: torneoId)));
      }),
      _Item('Estadísticas', 'PJ • PG • Sets • Pts', Icons.bar_chart,
          [VoleyColors.violet, VoleyColors.pink], () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => StatsScreen(torneoId: torneoId)));
      }),
      _Item('Posiciones', 'Tabla del torneo', Icons.leaderboard,
          [VoleyColors.green, VoleyColors.teal], () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => StandingsScreen(torneoId: torneoId)));
      }),
      _Item('Historial', 'Resultados + PDF', Icons.history,
          [VoleyColors.blue, VoleyColors.violet], () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => HistoryScreen(torneoId: torneoId)));
      }),
      _Item('Editar torneo', 'Equipos • cédula', Icons.edit,
          [VoleyColors.pink, VoleyColors.orange], () {
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => EditTournamentScreen(torneoId: torneoId)));
      }),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(t.nombre)),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 14, 16, 4),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [VoleyColors.navy, Color(0xFF134E5E)]),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Text('🏐', style: TextStyle(fontSize: 30)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                      '${t.equipos.length} equipos • ${t.resultados.length} partidos jugados',
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color: VoleyColors.yellow,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                      t.resultados.isEmpty ? 'INICIO' : 'EN VIVO',
                      style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: VoleyColors.navy)),
                ),
              ],
            ),
          ),
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: items.length,
              itemBuilder: (c, i) {
                final it = items[i];
                return InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: it.fn,
                  child: Ink(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                          colors: it.grad,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: it.grad.last.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color:
                                Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(it.icon,
                              color: Colors.white, size: 30),
                        ),
                        const Spacer(),
                        Text(it.titulo,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold)),
                        Text(it.sub,
                            style: TextStyle(
                                color: Colors.white
                                    .withValues(alpha: 0.85),
                                fontSize: 12)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Item {
  final String titulo;
  final String sub;
  final IconData icon;
  final List<Color> grad;
  final VoidCallback fn;
  _Item(this.titulo, this.sub, this.icon, this.grad, this.fn);
}
