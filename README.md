# Torneo Voleibol — App multiplataforma (EXE / DEB / IPA / APK)

App en Flutter para control de torneos de voleibol. Un solo código genera:
- Android APK / AAB
- iOS IPA
- Windows EXE (MSIX/EXE)
- Linux DEB

## Funcionalidad implementada (según pedido)

- **Home:** Agregar torneo / Continuar torneo (lista guardada en memoria local) / Configuración (drawer: tono oscuro, borrado).
- **Agregar torneo:** nombre, formato (2 de 3 / 3 de 5), sistema (Round Robin 1 vuelta, 2 vueltas, Eliminación directa).
- **Equipos:** agregar, lista, editar nombre, borrar, cargar cédula.
- **Cédula:** foto (galería), nombre (obligatorio), apellido, fecha nacimiento, teléfono. Sin límite. Guardado incremental. Editar/eliminar.
- **Dashboard torneo:** Rol de juegos, Jornada actual, Estadísticas, Posiciones, Historial, Editar torneo.
- **Rol de juegos:** se genera al entrar. RR2 muestra Primera/Segunda vuelta. Switch Programar ON (manda a Jornada) / OFF (quita). En directa genera rondas y avanza ganadores automáticamente.
- **Jornada actual:** partidos programados + Iniciar encuentro.
- **Roster:** lista de cada equipo + número de playera, error si duplicado (0-99), mínimo 6 con número por equipo. Capturar nuevo jugador (guarda en cédula). Sin número = no juega.
- **Lado y saque:** quién es lado A y quién saca. Guardar y continuar.
- **Alineación 1-6:** arriba el que saca, abajo el que recibe.
- **Juego en vivo:**
  - Nombres, sets ganados, puntos grandes, +1/-1, Tiempo, Cambio.
  - Cambio con reglas FIVB: 6 por set, titular reingresa 1 vez solo por su sustituto, sustituto que salió no vuelve.
  - Tiempos FIVB: 2 por set de 30s.
  - Cancha con zaguero/ataque/red/ataque/zaguero, layout pedido:
    `A: 5-4 / 6-3 / 1-2  | RED |  B: 2-1 / 3-6 / 4-5`, rotación manecillas, círculo amarillo al saque, números grandes.
  - Banca + registro tardío (asigna número de cédula).
  - Sanciones: tipo (6), equipo dropdown, jugador activo/banca o Equipo grupal, set + marcador auto. Se guarda todo el partido y sale en hoja final.
  - Cambio de lado manual + automático a los 8 en definitivo.
  - Sets a 25 / definitivo a 15 (3º o 5º), diferencia 2. Al cerrar set vuelve a alineación; si va a definitivo pide lado/saque de nuevo.
  - Final: popup con ganador grande, marcador, parciales, Guardar y salir (guarda jugadores + sanciones, vuelve a Jornada).
- **Estadísticas/Posiciones:** PJ PG PP SF SC DifS PF PC DifP, orden PG > DifSets > DifPuntos. Export PDF.
- **Historial:** todos los jugados + export PDF. Hoja de partido también exportable.
- **Editar torneo:** agregar equipo nuevo (actualiza fixture automáticamente), editar cédulas existentes.

## Persistencia
`shared_preferences` JSON local. Sin backend.

## Compilar

```bash
cd torneo_voleibol
flutter pub get
flutter run

flutter build apk --release
flutter build appbundle --release
flutter build ipa --release        # requiere macOS + Xcode
flutter build windows --release    # EXE/MSIX
flutter build linux --release      # luego .deb con electron-installer o cpack
```

APK debug ya verificado: `build/app/outputs/flutter-apk/app-debug.apk`.

## Reglas FIVB aplicadas (resumen)
Ver `lib/rules.dart`. Líbero no implementado como rol separado (se trata como jugador normal); sustitución excepcional por lesión se pide hacerla como cambio manual + sanción si aplica.

## Estructura
- `lib/models.dart` — Torneo/Equipo/Jugador/Partido/Resultado/Sanción
- `lib/store.dart` — estado + estadísticas
- `lib/schedule.dart` — round robin / directa
- `lib/rules.dart` — sets, tiempos, sustituciones, rotación
- `lib/screens/` — home, form, teams, dashboard, fixture, jornada, roster, side_serve, lineup, live_game, stats, edit
