import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'store.dart';
import 'theme.dart';
import 'screens/home.dart';

/// Oculta las barras del sistema (navegación y estado) para que no tapen
/// los botones. Con immersiveSticky reaparecen con un deslizamiento desde
/// el borde y se vuelven a ocultar solas.
Future<void> ocultarBarras() {
  return SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ocultarBarras();
  final store = AppStore();
  await store.cargar();
  runApp(ChangeNotifierProvider.value(value: store, child: const App()));
}

class App extends StatefulWidget {
  const App({super.key});
  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Al volver a la app (p. ej. tras compartir un PDF) se reocultan.
    if (state == AppLifecycleState.resumed) ocultarBarras();
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<AppStore>();
    return MaterialApp(
      title: 'Volleyball Tournament Control',
      debugShowCheckedModeBanner: false,
      themeMode: store.oscuro ? ThemeMode.dark : ThemeMode.light,
      theme: voleyLight(),
      darkTheme: voleyDark(),
      home: const HomeScreen(),
    );
  }
}
