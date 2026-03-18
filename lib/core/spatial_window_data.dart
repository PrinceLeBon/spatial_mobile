import 'package:flutter/material.dart';

/// Modèle de données pour une fenêtre flottante spatiale.
///
/// Chaque [SpatialWindowData] décrit :
/// - sa position dans l'espace 2D de l'écran
/// - sa profondeur Z simulée (0.0 = proche, 1.0 = loin)
/// - son contenu
/// - son accent coloré
@immutable
class SpatialWindowData {
  const SpatialWindowData({
    required this.id,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.position,
    required this.size,
    required this.depth,
  });

  /// Identifiant unique de la fenêtre
  final String id;

  /// Titre affiché dans la barre de titre
  final String title;

  /// Icône de la fenêtre
  final IconData icon;

  /// Couleur d'accent (utilisée pour le reflet coloré et la bordure top)
  final Color accentColor;

  /// Position initiale sur l'écran (coin supérieur gauche)
  final Offset position;

  /// Taille de la fenêtre
  final Size size;

  /// Profondeur Z normalisée [0.0, 1.0].
  /// 0.0 = premier plan (net, ombre forte)
  /// 1.0 = arrière-plan (flou plus marqué, ombre diffuse)
  final double depth;

  /// Calcule le sigma de blur en fonction de la profondeur.
  /// Les fenêtres lointaines sont plus floues (effet de champ).
  double get blurSigma => 20.0 + depth * 14.0;

  /// L'opacité du fond verre varie avec la profondeur :
  /// fenêtres proches = légèrement moins transparentes.
  double get glassOpacity => 0.10 + (1.0 - depth) * 0.08;

  /// Échelle visuelle basée sur la profondeur (perspective simulée).
  double get depthScale => 1.0 - depth * 0.12;

  SpatialWindowData copyWith({Offset? position, double? depth, Size? size}) {
    return SpatialWindowData(
      id: id,
      title: title,
      icon: icon,
      accentColor: accentColor,
      position: position ?? this.position,
      size: size ?? this.size,
      depth: depth ?? this.depth,
    );
  }
}
