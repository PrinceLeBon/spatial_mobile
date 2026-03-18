# Spatial Mobile

> Interface spatiale premium pour mobile, inspirée de visionOS — adaptée au monde réel.

![Flutter](https://img.shields.io/badge/Flutter-3.24+-02569B?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.4+-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-lightgrey)
![License](https://img.shields.io/badge/License-MIT-green)

---

## Aperçu

**Spatial Mobile** simule une interface à profondeur visuelle sur mobile : fenêtres flottantes en glassmorphism, parallaxe gyroscopique temps réel, reflets dynamiques et ombres réalistes — entièrement construit avec les fondamentaux Flutter (Matrix4, CustomPainter, BackdropFilter).

### Effets implémentés

| Effet | Technique |
|-------|-----------|
| Perspective 3D réelle | `Matrix4` + `setEntry(3, 2, f)` |
| Parallaxe différentiel | Accéléromètre + filtre EMA |
| Glassmorphism avancé | `BackdropFilter` + blur variable par profondeur |
| Reflets dynamiques | `CustomPainter` (4 passes) |
| Ombres réalistes | `BoxShadow` dynamique selon l'inclinaison |
| Fond spatial animé | `CustomPainter` + champ d'étoiles procédural |

---

## Démarrage rapide

### Prérequis

- Flutter ≥ 3.24
- Dart ≥ 3.4
- **Appareil physique recommandé** (le gyroscope ne fonctionne pas sur simulateur)

### Installation

```bash
git clone https://github.com/PrinceLeBon/spatial_mobile.git
cd spatial_mobile
flutter pub get
flutter run --release
```

> ⚠️ Toujours tester en `--release` pour les vraies performances.
> Le mode debug désactive plusieurs optimisations Impeller.

---

## Architecture

```
lib/
├── main.dart                            # Bootstrap, SystemChrome
├── core/
│   ├── spatial_theme.dart               # Constantes visuelles centralisées
│   └── spatial_window_data.dart         # Modèle immuable d'une fenêtre
├── sensors/
│   ├── gyro_service.dart                # Accéléromètre → EMA → ValueNotifier
│   └── spatial_windows_controller.dart  # ChangeNotifier : positions, z-order
└── ui/
    ├── painters/
    │   ├── glass_reflection_painter.dart # Reflets dynamiques (CustomPainter)
    │   └── space_background_painter.dart # Fond étoilé (CustomPainter)
    ├── screens/
    │   └── spatial_home_screen.dart      # Orchestration des 3 couches de rendu
    ├── widgets/
    │   └── spatial_title_bar.dart        # Barre de titre réutilisable
    └── windows/
        ├── spatial_window.dart           # Widget principal (Matrix4 + blur)
        └── window_contents.dart          # Music, Weather, Notifications, Clock
```

**Principe de séparation des couches :**
`ui` → `sensors` → `core`. Jamais l'inverse.

---

## Dépendances

| Package | Usage |
|---------|-------|
| [`sensors_plus`](https://pub.dev/packages/sensors_plus) | Lecture de l'accéléromètre |
| [`google_fonts`](https://pub.dev/packages/google_fonts) | Typographie Inter |

> Aucun package de glassmorphism ou d'animation pré-construit — tout est implémenté manuellement.

---

## Documentation technique

La documentation complète est dans [`docs/`](./docs/) :

| Fichier | Contenu |
|---------|---------|
| [`00_INDEX.md`](./docs/00_INDEX.md) | Table des matières |
| [`01_ARCHITECTURE.md`](./docs/01_ARCHITECTURE.md) | Structure, flux de données, rôle de chaque fichier |
| [`02_IMPLEMENTATION_PLAN.md`](./docs/02_IMPLEMENTATION_PLAN.md) | Plan d'implémentation en 10 étapes |
| [`03_TECHNICAL_DEEP_DIVE.md`](./docs/03_TECHNICAL_DEEP_DIVE.md) | Matrix4, EMA, glassmorphism, pièges fréquents |
| [`04_PERFORMANCE.md`](./docs/04_PERFORMANCE.md) | Impeller, RepaintBoundary, budget GPU/CPU |
| [`05_BONUS_UX_PREMIUM.md`](./docs/05_BONUS_UX_PREMIUM.md) | Spring physics, Fragment shaders, momentum drag |

---

## Points techniques saillants

### Matrix4 — Perspective réelle

```dart
Matrix4.identity()
  ..setEntry(3, 2, 0.0018)             // Active la projection perspective
  ..translateByDouble(tx, ty, 0.0, 1.0) // Parallaxe 2D
  ..rotateX(rotX)                       // Inclinaison avant/arrière
  ..rotateY(rotY)                       // Inclinaison gauche/droite
  ..scaleByDouble(scale, scale, 1.0, 1.0); // Scale par profondeur
```

### Filtre EMA sur le gyroscope

```dart
// α = 0.08 → fluide sans lag perceptible
_smoothX = 0.08 * rawX + 0.92 * _smoothX;
```

### Architecture rebuild zéro

Le gyroscope émet 50 événements/sec. **0 widget Flutter ne rebuilde** pendant le mouvement — seuls les `CustomPainter` repaignent via leur propre layer Impeller.

---

## Licence

MIT — libre d'utilisation, modification et distribution.
