import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../store.dart';
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
    if (t == null) return const Scaffold(body: Center(child: Text('Torneo no encontrado')));
    return Scaffold(
      appBar: AppBar(title: Text(t.nombre)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('${t.equipos.length} equipos • ${t.resultados.length} partidos jugados',
              style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 12),
          _btn(context, 'Rol de juegos', Icons.list_alt, () {
            store.asegurarFixture(t);
            Navigator.push(context, MaterialPageRoute(builder: (_) => FixtureScreen(torneoId: torneoId)));
          }),
          _btn(context, 'Jornada actual', Icons.play_arrow, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => JornadaScreen(torneoId: torneoId)));
          }),
          _btn(context, 'Estadísticas', Icons.bar_chart, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => StatsScreen(torneoId: torneoId)));
          }),
          _btn(context, 'Posiciones', Icons.leaderboard, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => StandingsScreen(torneoId: torneoId)));
          }),
          _btn(context, 'Historial de resultados', Icons.history, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => HistoryScreen(torneoId: torneoId)));
          }),
          _btn(context, 'Editar torneo', Icons.edit, () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => EditTournamentScreen(torneoId: torneoId)));
          }),
        ],
      ),
    );
  }

  Widget _btn(BuildContext c, String titulo, IconData icono, VoidCallback fn) {
    return Card(
      child: ListTile(
        leading: Icon(icono),
        title: Text(titulo),
        trailing: const Icon(Icons.arrow_forward_ios),
        onTap: fn,
      ),
    );
  }
}
