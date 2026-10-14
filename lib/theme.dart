import 'package:flutter/material.dart';

class VoleyColors {
  static const navy = Color(0xFF0B1E3B);
  static const teal = Color(0xFF00BFA6);
  static const orange = Color(0xFFFF6F00);
  static const yellow = Color(0xFFFFC107);
  static const violet = Color(0xFF7C4DFF);
  static const pink = Color(0xFFFF4081);
  static const blue = Color(0xFF2979FF);
  static const green = Color(0xFF00E676);
}

ThemeData voleyLight() {
  final base = ThemeData.light(useMaterial3: true);
  final scheme = ColorScheme.fromSeed(
    seedColor: VoleyColors.teal,
    primary: VoleyColors.teal,
    secondary: VoleyColors.orange,
  );
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF1F5F9),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      foregroundColor: Colors.white,
      backgroundColor: VoleyColors.navy,
    ),
    cardTheme: CardThemeData(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
  );
}

ThemeData voleyDark() {
  final base = ThemeData.dark(useMaterial3: true);
  final scheme = ColorScheme.fromSeed(
    seedColor: VoleyColors.teal,
    brightness: Brightness.dark,
    primary: VoleyColors.teal,
    secondary: VoleyColors.orange,
  );
  return base.copyWith(
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFF0A1428),
    appBarTheme: const AppBarTheme(
      centerTitle: true,
      foregroundColor: Colors.white,
      backgroundColor: Color(0xFF0B1E3B),
    ),
    cardTheme: CardThemeData(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
      ),
    ),
  );
}

class GradientButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final List<Color> gradient;
  final VoidCallback? onPressed;
  const GradientButton({
    super.key,
    required this.icon,
    required this.label,
    this.subtitle,
    this.gradient = const [VoleyColors.teal, VoleyColors.blue],
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onPressed == null ? 0.5 : 1,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: gradient),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: gradient.last.withValues(alpha: 0.4),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.bold)),
                    if (subtitle != null)
                      Text(subtitle!,
                          style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}

class VoleyHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  const VoleyHeader({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [VoleyColors.navy, Color(0xFF134E5E), VoleyColors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4)),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.asset('assets/icon.png',
                  errorBuilder: (_, __, ___) => Container(
                      color: Colors.white,
                      child: const Icon(Icons.sports_volleyball,
                          size: 40, color: VoleyColors.teal))),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _chip('🏐 2de3 • 3de5'),
                    const SizedBox(width: 6),
                    _chip('RR • Directa'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chip(String t) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: VoleyColors.yellow,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(t,
          style: const TextStyle(
              fontSize: 11, fontWeight: FontWeight.bold, color: VoleyColors.navy)),
    );
  }
}
