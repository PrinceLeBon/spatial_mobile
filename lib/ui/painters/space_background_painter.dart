import 'dart:math' as math;
import 'package:flutter/material.dart';

/// [SpaceBackgroundPainter] — Peint le fond spatial animé.
///
/// Contient :
/// - Un champ d'étoiles générées procéduralement (positions stables, opacités
///   qui pulsent lentement → pas d'AnimationController ici, le parent appelle
///   repaint via un Ticker).
/// - Une nébuleuse : deux grands blobs de couleur avec RadialGradient très doux.
/// - Un effet de parallaxe : les étoiles se décalent selon l'inclinaison,
///   les étoiles proches bougent plus que les lointaines (simule la profondeur).
///
/// ─── Stratégie performance ───────────────────────────────────────────────────
/// • Les positions d'étoiles sont pré-calculées dans le constructeur → pas de
///   calcul aléatoire dans paint().
/// • Les étoiles sont regroupées par couche de profondeur pour limiter les
///   appels drawCircle (on pourrait aussi utiliser drawPoints pour un batch).
/// • shouldRepaint ne retourne true que si tilt OU animOffset change.
/// ─────────────────────────────────────────────────────────────────────────────
class SpaceBackgroundPainter extends CustomPainter {
  SpaceBackgroundPainter({
    required this.tiltX,
    required this.tiltY,
    required this.animOffset,
    required List<StarData> stars,
  }) : _stars = stars;

  final double tiltX;
  final double tiltY;

  /// Valeur oscillante [0, 1] fournie par un AnimationController (pulse étoiles)
  final double animOffset;

  final List<StarData> _stars;

  @override
  void paint(Canvas canvas, Size size) {
    // ── Fond dégradé ──────────────────────────────────────────────────────
    final bgPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xFF060B1A), Color(0xFF0A1428), Color(0xFF050810)],
        stops: [0.0, 0.5, 1.0],
      ).createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, bgPaint);

    // ── Nébuleuse 1 : haut gauche ─────────────────────────────────────────
    _drawNebula(
      canvas,
      size,
      center: Offset(
        size.width * (0.15 + tiltX * 0.04),
        size.height * (0.18 + tiltY * 0.03),
      ),
      radius: size.width * 0.65,
      color: const Color(0xFF1A3A8F),
      opacity: 0.18,
    );

    // ── Nébuleuse 2 : bas droite ──────────────────────────────────────────
    _drawNebula(
      canvas,
      size,
      center: Offset(
        size.width * (0.85 + tiltX * 0.06),
        size.height * (0.75 + tiltY * 0.05),
      ),
      radius: size.width * 0.55,
      color: const Color(0xFF3A1A6F),
      opacity: 0.14,
    );

    // ── Étoiles par couche de profondeur ──────────────────────────────────
    for (final star in _stars) {
      _drawStar(canvas, size, star);
    }
  }

  void _drawNebula(
    Canvas canvas,
    Size size, {
    required Offset center,
    required double radius,
    required Color color,
    required double opacity,
  }) {
    final paint = Paint()
      ..shader = RadialGradient(
        colors: [
          color.withValues(alpha: opacity),
          color.withValues(alpha: opacity * 0.3),
          Colors.transparent,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, paint);
  }

  void _drawStar(Canvas canvas, Size size, StarData star) {
    // Chaque couche de parallaxe se déplace proportionnellement à sa profondeur
    // Les étoiles proches (layer 1) bougent plus → effet de profondeur naturel
    final parallaxFactor = star.layer * 14.0;
    final dx = tiltX * parallaxFactor;
    final dy = tiltY * parallaxFactor;

    final x = (star.x * size.width + dx).clamp(0.0, size.width);
    final y = (star.y * size.height + dy).clamp(0.0, size.height);

    // Pulsation : chaque étoile a un offset de phase unique → scintillement asynchrone
    final pulse = (math.sin(animOffset * math.pi * 2 + star.phase) + 1) / 2;
    final opacity = star.baseOpacity * (0.5 + pulse * 0.5);

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: opacity)
      ..maskFilter = star.layer > 0.5
          ? const MaskFilter.blur(BlurStyle.normal, 0.8)
          : null;

    canvas.drawCircle(Offset(x, y), star.radius, paint);
  }

  @override
  bool shouldRepaint(SpaceBackgroundPainter old) {
    return old.tiltX != tiltX ||
        old.tiltY != tiltY ||
        old.animOffset != animOffset;
  }
}

/// Données immuables d'une étoile, générées une seule fois au démarrage.
class StarData {
  const StarData({
    required this.x,
    required this.y,
    required this.radius,
    required this.baseOpacity,
    required this.layer,
    required this.phase,
  });

  /// Position normalisée [0, 1]
  final double x;
  final double y;

  /// Rayon en pixels
  final double radius;

  /// Opacité de base [0, 1]
  final double baseOpacity;

  /// Couche de profondeur [0, 1] : 0 = très loin, 1 = proche
  final double layer;

  /// Phase de scintillement [0, 2π]
  final double phase;

  /// Génère N étoiles réparties en 3 couches de profondeur.
  static List<StarData> generate(int count, {int seed = 42}) {
    final rng = math.Random(seed);
    return List.generate(count, (i) {
      final layer = (i % 3 == 0)
          ? 0.15
          : (i % 3 == 1)
          ? 0.45
          : 0.85;
      return StarData(
        x: rng.nextDouble(),
        y: rng.nextDouble(),
        radius: 0.4 + rng.nextDouble() * 1.2 * layer,
        baseOpacity: 0.3 + rng.nextDouble() * 0.5,
        layer: layer,
        phase: rng.nextDouble() * math.pi * 2,
      );
    });
  }
}
