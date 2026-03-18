import 'package:flutter/material.dart';

/// [GlassReflectionPainter] — CustomPainter qui dessine :
///
/// 1. Un reflet de lumière ambiante en haut à gauche (toujours présent)
/// 2. Un highlight dynamique dont la position suit l'inclinaison du téléphone
/// 3. Une frange chromatique sur le bord supérieur de la fenêtre
/// 4. Un vignettage interne subtil pour simuler la courbure du verre
///
/// ─── Pourquoi CustomPainter ici ? ───────────────────────────────────────────
/// BackdropFilter + BoxDecoration peuvent gérer la plupart des effets statiques.
/// Mais les reflets dynamiques DOIVENT être dessinés dans canvas.drawPath()
/// car leur position, opacité et gradient changent à chaque frame selon le
/// gyroscope. Un widget classique forcerait un rebuild → trop coûteux.
/// CustomPainter + [shouldRepaint] bien défini = repaint uniquement si nécessaire.
/// ─────────────────────────────────────────────────────────────────────────────
class GlassReflectionPainter extends CustomPainter {
  const GlassReflectionPainter({
    required this.tiltX,
    required this.tiltY,
    required this.accentColor,
    required this.borderRadius,
    required this.depth,
  });

  /// Inclinaison X normalisée [-1, 1] (gauche/droite)
  final double tiltX;

  /// Inclinaison Y normalisée [-1, 1] (avant/arrière)
  final double tiltY;

  /// Couleur d'accent de la fenêtre pour teinter légèrement le reflet
  final Color accentColor;

  final double borderRadius;

  /// Profondeur [0,1] → les fenêtres lointaines ont des reflets plus atténués
  final double depth;

  @override
  void paint(Canvas canvas, Size size) {
    final rRect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );

    // Clip au contour de la fenêtre pour que rien ne déborde
    canvas.save();
    canvas.clipRRect(rRect);

    _drawAmbientTopHighlight(canvas, size);
    _drawDynamicSpecular(canvas, size);
    _drawChromaticEdge(canvas, size);
    _drawInnerVignette(canvas, size);

    canvas.restore();
  }

  // ── 1. Reflet ambiant en haut : bande de lumière douce ──────────────────
  void _drawAmbientTopHighlight(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height * 0.38);
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withValues(alpha: 0.13 * (1.0 - depth * 0.5)),
          Colors.transparent,
        ],
      ).createShader(rect);

    // Chemin en forme de lentille : plus visible en haut
    final path = Path()
      ..moveTo(borderRadius, 0)
      ..lineTo(size.width - borderRadius, 0)
      ..quadraticBezierTo(size.width, 0, size.width, borderRadius)
      ..lineTo(size.width, size.height * 0.20)
      ..quadraticBezierTo(
        size.width / 2,
        size.height * 0.42,
        0,
        size.height * 0.20,
      )
      ..lineTo(0, borderRadius)
      ..quadraticBezierTo(0, 0, borderRadius, 0)
      ..close();

    canvas.drawPath(path, paint);
  }

  // ── 2. Spéculaire dynamique : spot de lumière qui suit l'inclinaison ────
  void _drawDynamicSpecular(Canvas canvas, Size size) {
    // Position du spot : centré par défaut, décalé par le tilt
    // tiltX > 0 = téléphone incliné à droite → lumière va à droite
    final cx = size.width * (0.30 + tiltX * 0.35);
    final cy = size.height * (0.20 + tiltY * 0.20);
    final radius = size.width * 0.55;

    final opacity = (0.12 * (1.0 - depth * 0.4)).clamp(0.0, 1.0);

    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.white.withValues(alpha: opacity * 1.8),
          accentColor.withValues(alpha: opacity * 0.5),
          Colors.transparent,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(cx, cy), radius: radius));

    canvas.drawCircle(Offset(cx, cy), radius, paint);
  }

  // ── 3. Frange chromatique sur le bord supérieur ─────────────────────────
  // Simule la dispersion lumineuse sur un verre épais
  void _drawChromaticEdge(Canvas canvas, Size size) {
    final intensity = (0.4 + tiltY * 0.3).clamp(0.0, 1.0);

    // Ligne bleue-blanche en haut
    final topPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          Colors.white.withValues(
            alpha: 0.55 * intensity * (1.0 - depth * 0.6),
          ),
          accentColor.withValues(alpha: 0.3 * intensity),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 1.5))
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    final topPath = Path()
      ..moveTo(borderRadius, 0)
      ..lineTo(size.width - borderRadius, 0);

    canvas.drawPath(topPath, topPaint);

    // Ligne secondaire 1px en dessous (effet prismatique)
    final secondaryPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.12 * intensity)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;

    final secondaryPath = Path()
      ..moveTo(borderRadius + 4, 1.5)
      ..lineTo(size.width - borderRadius - 4, 1.5);

    canvas.drawPath(secondaryPath, secondaryPaint);
  }

  // ── 4. Vignettage interne : bords sombres = profondeur ──────────────────
  void _drawInnerVignette(Canvas canvas, Size size) {
    final vignetteOpacity = 0.18 + depth * 0.12;

    final paint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          Colors.transparent,
          Colors.black.withValues(alpha: vignetteOpacity),
        ],
        stops: const [0.55, 1.0],
      ).createShader(Offset.zero & size);

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Offset.zero & size,
        Radius.circular(borderRadius),
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(GlassReflectionPainter old) {
    // Ne repeint que si les valeurs changent réellement (évite les repaints à vide)
    return old.tiltX != tiltX ||
        old.tiltY != tiltY ||
        old.accentColor != accentColor ||
        old.depth != depth;
  }
}
