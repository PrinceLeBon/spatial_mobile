# 🏗️ Architecture du projet

---

## Structure des dossiers

```
lib/
├── main.dart
│   └── Bootstrap : SystemChrome (immersive + portrait), runApp
│
├── core/                          ← MODÈLES & CONSTANTES (pur Dart, zéro Flutter)
│   ├── spatial_theme.dart         ← Palette, constantes visuelles, paramètres parallaxe
│   └── spatial_window_data.dart   ← Modèle immuable d'une fenêtre (@immutable)
│
├── sensors/                       ← LOGIQUE MÉTIER (state, capteurs)
│   ├── gyro_service.dart          ← Lecture accéléromètre → EMA → ValueNotifier<GyroState>
│   └── spatial_windows_controller.dart ← ChangeNotifier : positions, z-order
│
└── ui/                            ← PRÉSENTATION UNIQUEMENT
    ├── painters/
    │   ├── glass_reflection_painter.dart ← CustomPainter : 4 passes de reflets
    │   └── space_background_painter.dart ← CustomPainter : étoiles + nébuleuse
    ├── screens/
    │   └── spatial_home_screen.dart      ← Orchestration des 3 couches de rendu
    ├── widgets/
    │   └── spatial_title_bar.dart        ← Barre de titre réutilisable (const)
    └── windows/
        ├── spatial_window.dart           ← Le widget verre (Matrix4 + BackdropFilter)
        └── window_contents.dart          ← Contenus : Music, Weather, Notif, Clock
```

---

## Flux de données

```
Accéléromètre (50Hz)
       │
       ▼
 GyroService.start()
  ├─ EMA smoothing (α=0.08)
  ├─ Dead zone 2%
  └─ ValueNotifier<GyroState>
              │
    ┌─────────┴──────────┐
    │                    │
    ▼                    ▼
_BackgroundLayer    _GyroWindowWrapper (x4)
(AnimatedBuilder)   (ValueListenableBuilder)
       │                    │
       ▼                    ▼
SpaceBackgroundPainter  SpatialWindow
  repaint/frame         ├─ Matrix4 (perspective + parallaxe)
                        ├─ BackdropFilter (blur)
                        └─ GlassReflectionPainter (repaint)


GestureDetector (drag)
       │
       ▼
SpatialWindowsController.updatePosition()
       │
       ▼
ListenableBuilder → _WindowsLayer rebuild
(Positioned repositionné)
```

---

## Rôle précis de chaque fichier

### `core/spatial_theme.dart`
Fichier de **constantes visuelles centralisées**. Ne contient aucun widget Flutter.
Permet de modifier toute la palette / les paramètres d'effet en un seul endroit.

Constantes clés :
```dart
static const double perspectiveFactor = 0.0018;   // 1/focalLength
static const double parallaxAmplitude = 18.0;      // pixels max de déplacement
static const double gyroSmoothFactor  = 0.08;      // α du filtre EMA
```

### `core/spatial_window_data.dart`
Modèle **immuable** (`@immutable`). Contient la logique dérivée de `depth` :
- `blurSigma` → sigma du BackdropFilter selon la profondeur
- `glassOpacity` → transparence du fond verre
- `depthScale` → facteur d'échelle (fenêtres lointaines = plus petites)

> **Pourquoi immuable ?** Dart peut optimiser les comparaisons. Facilite
> les updates via `copyWith` sans mutation d'état partagé.

### `sensors/gyro_service.dart`
- Écoute `accelerometerEventStream` (50Hz via `SensorInterval.gameInterval`)
- Applique un **filtre EMA** (Exponential Moving Average)
- Expose un seul `ValueNotifier<GyroState>` — les widgets s'abonnent sans setState

> **Pourquoi l'accéléromètre et pas le gyroscope ?**
> Le gyroscope donne une vitesse angulaire → intégration → drift cumulatif.
> L'accéléromètre mesure la gravité → donne l'inclinaison absolue, stable,
> parfaite pour un effet "lévitation" sans dérive.

### `sensors/spatial_windows_controller.dart`
`ChangeNotifier` qui maintient la **liste ordonnée des fenêtres** (z-order).
Expose deux mutations : `updatePosition()` (drag) et `bringToFront()` (tap).

### `ui/painters/glass_reflection_painter.dart`
`CustomPainter` avec **4 passes de dessin** :
1. Highlight ambiant (lentille en haut)
2. Specular dynamique (suit le tilt)
3. Frange chromatique (bord supérieur prismatique)
4. Vignettage interne

`shouldRepaint` ne retourne `true` que si `tiltX`, `tiltY` ou `accentColor` changent.

### `ui/painters/space_background_painter.dart`
- 160 étoiles générées **une seule fois** au démarrage (`StarData.generate()`)
- 3 couches de profondeur avec parallaxe différentiel
- Pulsation asynchrone par phase individuelle (scintillement naturel)

### `ui/screens/spatial_home_screen.dart`
**Chef d'orchestre.** Découpe le rendu en 3 sous-arbres indépendants :
- `_BackgroundLayer` → isolé par `RepaintBoundary`
- `_WindowsLayer` → écoute `SpatialWindowsController`
- `_GyroWindowWrapper` → le plus petit arbre qui écoute le gyro

### `ui/windows/spatial_window.dart`
Le widget le plus complexe. Assemble par couche :
1. `BackdropFilter` (blur)
2. Fond verre avec gradient d'accent
3. Contenu
4. `GlassReflectionPainter`
5. Bordure extérieure

Calcule le `Matrix4` avec perspective, translation, rotation et scale.

---

## Règle d'or de l'architecture

> Chaque couche ne connaît que la couche immédiatement en dessous.
> `ui` connaît `sensors` et `core`. `sensors` connaît `core`. `core` est autonome.
> Jamais l'inverse.
