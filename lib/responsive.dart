import 'package:flutter/material.dart';

/// Puntos de corte y ayudas para adaptar la app a celular y tableta.
/// Flutter trabaja en dp (píxeles independientes de densidad), así que el
/// mismo APK se ve nítido en teléfono y tableta; aquí se decide cómo
/// aprovechar el ancho extra.
class Resp {
  static const double telefono = 420;
  static const double tableta = 600;
  static const double amplio = 800;

  /// Columnas de rejilla según el ancho disponible.
  static int cols(double width,
          {double minTile = 240, int minCols = 2, int maxCols = 4}) =>
      (width ~/ minTile).clamp(minCols, maxCols).toInt();

  static bool esAngosto(BuildContext c) =>
      MediaQuery.sizeOf(c).width < telefono;
  static bool esAmplio(BuildContext c) =>
      MediaQuery.sizeOf(c).width >= amplio;
}

/// Limita el ancho del contenido en tabletas/escritorio sin romper
/// layouts con Expanded (usar solo dentro de scrolls, alrededor de
/// tarjetas y botones, nunca alrededor de Column con Expanded).
class MaxWidth extends StatelessWidget {
  final Widget child;
  final double max;
  const MaxWidth({super.key, required this.child, this.max = 700});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: max),
        child: child,
      ),
    );
  }
}
