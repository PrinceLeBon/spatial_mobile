import 'package:flutter/material.dart';

/// Palette de couleurs et constantes visuelles de l'interface Spatial Mobile.
/// Inspiré de la densité visuelle de visionOS : couleurs désaturées, teintes
/// froides, dégradés subtils et lumière ambiante diffuse.
abstract class SpatialTheme {
  // ── Fond principal ─────────────────────────────────────────────────────────
  static const Color backgroundDeep = Color(0xFF060A14);
  static const Color backgroundMid = Color(0xFF0D1528);

  // Gradient d'arrière-plan : ciel nocturne avec légère nébuleuse
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF070D1F), Color(0xFF0A1528), Color(0xFF060912)],
    stops: [0.0, 0.5, 1.0],
  );

  // ── Glassmorphism ──────────────────────────────────────────────────────────
  /// Teinte de base du verre. Blanc très transparent.
  static const Color glassBase = Color(0x18FFFFFF);

  /// Bordure lumineuse supérieure (reflet de lumière ambiante)
  static const Color glassBorderTop = Color(0x55FFFFFF);

  /// Bordure inférieure plus sombre
  static const Color glassBorderBottom = Color(0x12FFFFFF);

  /// Tint subtil bleu-violet pour effet "screen phosphor"
  static const Color glassTint = Color(0x0A6EA8F5);

  // ── Ombres ─────────────────────────────────────────────────────────────────
  static const Color shadowColor = Color(0xCC000000);
  static const Color shadowAccent = Color(0x40000AFF);

  // ── Couleurs d'accentuation par fenêtre ───────────────────────────────────
  static const Color accentMusic = Color(0xFF7C5CBF);
  static const Color accentWeather = Color(0xFF2E86AB);
  static const Color accentNotif = Color(0xFF3D9B8A);
  static const Color accentClock = Color(0xFFBF7340);

  // ── Texte ─────────────────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xF2FFFFFF);
  static const Color textSecondary = Color(0x99FFFFFF);
  static const Color textTertiary = Color(0x55FFFFFF);

  // ── Dimensions fenêtres ───────────────────────────────────────────────────
  static const double windowBorderRadius = 24.0;
  static const double windowBlurSigma = 28.0;

  // ── Paramètres de perspective ─────────────────────────────────────────────
  /// Facteur de perspective. Plus petit = effet plus prononcé.
  /// Valeur recommandée : 0.001 à 0.003
  static const double perspectiveFactor = 0.0018;

  /// Amplitude maximale du parallaxe en pixels (translation X/Y)
  static const double parallaxAmplitude = 18.0;

  /// Amplitude maximale de la rotation de parallaxe (en radians)
  static const double parallaxRotationAmplitude = 0.025;

  /// Facteur de lissage du gyroscope (lerp). Plus proche de 1 = réactif.
  static const double gyroSmoothFactor = 0.08;
}
