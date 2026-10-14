import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'store.dart';
import 'theme.dart';
import 'screens/home.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = AppStore();
  await store.cargar();
  runApp(ChangeNotifierProvider.value(value: store, child: const App()));
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return MaterialApp(
      title: 'Voleyball Tournament Control',
      debugShowCheckedModeBanner: false,
      themeMode: store.oscuro ? ThemeMode.dark : ThemeMode.light,
      theme: voleyLight(),
      darkTheme: voleyDark(),
      home: const HomeScreen(),
    );
  }
}
