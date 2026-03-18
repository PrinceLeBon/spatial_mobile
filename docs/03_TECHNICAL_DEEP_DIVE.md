# 🔬 Deep Dive Technique

> Explications détaillées de chaque mécanisme critique du projet.
> Pensé pour un développeur qui veut comprendre le **pourquoi**, pas juste le **quoi**.

---

## 1. Matrix4 et la perspective réelle

### La matrice de transformation 3D en Flutter

Flutter utilise des matrices 4×4 (espace homogène) pour les transformations 3D.
Voici ce que fait chaque composant de notre matrice :

```
Matrix4.identity()
  ..setEntry(3, 2, 0.0018)          // [1] Perspective
  ..translateByDouble(tx, ty, 0, 1) // [2] Translation parallaxe
  ..rotateX(rotX)                    // [3] Rotation avant/arrière
  ..rotateY(rotY)                    // [4] Rotation gauche/droite
  ..scaleByDouble(s, s, 1, 1)       // [5] Scale profondeur
```

### [1] `setEntry(3, 2, f)` — La ligne magique

```
Matrice perspective complète :
[ 1    0    0    0  ]
[ 0    1    0    0  ]
[ 0    0    1    0  ]
[ 0    0    f    1  ]  ← f = 1/focalLength
```

**Sans cette valeur :** Les rotations X/Y sont des rotations *orthographiques*
(flat). Un carré reste un carré même après rotateY(0.5). Pas de perspective.

**Avec cette valeur :** Les points 3D sont projetés correctement.
`f = 0.0018` ≈ `1/555px`. La fenêtre semble être à 555px de distance de l'œil.

**Choisir la bonne valeur de f :**
| `f` | Effet | Distance focale équivalente |
|-----|-------|----------------------------|
| 0.001 | Très subtil | 1000px |
| 0.0018 | Équilibre (recommandé) | ~555px |
| 0.003 | Prononcé | ~333px |
| 0.005 | Exagéré / "fisheye" | 200px |

### [2] Translation (parallaxe)

```dart
final tx = tiltX * amplitude * (1.0 - depth);
final ty = tiltY * amplitude * (1.0 - depth);
```

L'amplitude est modulée par `(1 - depth)` :
- `depth = 0.1` (fenêtre proche) → `factor = 0.9` → déplacement de 16.2px
- `depth = 0.65` (fenêtre lointaine) → `factor = 0.35` → déplacement de 6.3px

C'est le **mécanisme central** de l'illusion de profondeur. Sans ce différentiel,
toutes les fenêtres bougent ensemble → l'espace est plat.

### [3] & [4] Rotations X/Y

```dart
// tiltY (avant/arrière) → rotateX (bascule top/bottom)
// tiltX (gauche/droite) → rotateY (rotation autour de l'axe vertical)
final rotX = -tiltY * 0.025 * (1.0 - depth);
final rotY =  tiltX * 0.025 * (1.0 - depth);
```

**Amplitude de 0.025 rad ≈ 1.4°.** Très faible intentionnellement.
Au-delà de 3°, l'effet devient distrayant plutôt qu'élégant.
Sur visionOS, les rotations sont également imperceptibles — c'est subliminal.

---

## 2. Le filtre EMA (gyroscope)

### Pourquoi lisser ?

L'accéléromètre brut sur mobile contient :
1. Le signal réel (inclinaison)
2. Les vibrations haute fréquence (marche, vibration moteur)
3. Le bruit numérique du capteur (~0.01-0.05 m/s²)

Sans lissage : les fenêtres "tremblent" même au repos.

### L'Exponential Moving Average

```
s(t) = α × x(t) + (1 - α) × s(t-1)

Où :
  x(t) = valeur brute à l'instant t
  s(t) = valeur lissée
  α = facteur de lissage [0, 1]
```

**Propriété clé :** La réponse est exponentielle, pas linéaire.
Un grand changement est absorbé progressivement sur plusieurs frames.
C'est exactement le comportement "spring-like" qu'on veut.

**Implémentation :**
```dart
_smoothX = 0.08 * rawX + 0.92 * _smoothX;
```

**Dead zone :**
```dart
final magnitude = sqrt(_smoothX² + _smoothY²);
if (magnitude < 0.02) return; // Ignorer les micro-mouvements
```

Sans dead zone : chaque micro-vibration (poser le téléphone sur une table)
déclenche un repaint. Avec 2% de dead zone : aucun repaint inutile au repos.

---

## 3. Glassmorphism — Anatomie complète

### Les couches dans l'ordre

```
┌─────────────────────────────────┐
│ 5. Bordure extérieure (0.8px)   │
│ 4. GlassReflectionPainter       │
│ 3. Contenu de la fenêtre        │
│ 2. Fond verre + gradient accent │
│ 1. BackdropFilter (blur)        │
└─────────────────────────────────┘
        ↕ (ce qui est derrière)
   Fond étoilé / autres fenêtres
```

### Couche 1 : BackdropFilter

```dart
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
  child: const SizedBox.expand(), // NE PAS mettre le contenu ici
)
```

**Piège critique :** Mettre le contenu dans le `child` du `BackdropFilter`.
Beaucoup de tutoriels font ça et c'est **incorrect** : le `child` du
`BackdropFilter` n'est PAS flouté, il est affiché par-dessus.
Le blur s'applique à ce qui est **derrière** le widget, pas à son enfant.

**Valeur de sigma variable :**
```dart
double get blurSigma => 20.0 + depth * 14.0;
// depth=0.1 → sigma=21.4 (peu flou, proche)
// depth=0.65 → sigma=29.1 (plus flou, lointain)
```

Simule un effet de "champ de profondeur" : les objets loin sont plus flous.

### Couche 2 : Fond verre

```dart
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [
        Colors.white.withValues(alpha: 0.14),  // haut-gauche
        accentColor.withValues(alpha: 0.06),    // teinte accent
        Colors.white.withValues(alpha: 0.10),   // bas-droite
      ],
    ),
  ),
)
```

Le gradient directionnel simule la façon dont la lumière interagit différemment
selon l'angle d'incidence sur une surface de verre.

### Couche 4 : GlassReflectionPainter (4 passes)

**Passe 1 — Ambient highlight (statique)**

```
     ╭─────────────────╮   ← Fenêtre
    ░░░░░░░░░░░░░░░░░░░░   ← Gradient blanc → transparent
   ░░░░░░░░░░░░░░░░░░░░░
    ░░░░░░░░░░░░░░░░
         (vide)
```

Ce reflet est toujours là, quelle que soit l'inclinaison.
Il représente la lumière ambiante diffuse de la "scène" (comme un plafond lumineux).

**Passe 2 — Specular dynamique (tiltX/Y)**

```
// Position du spot
cx = width * (0.30 + tiltX * 0.35)
// → tiltX=-1 : spot à gauche (x = 0.30 - 0.35 = -0.05, clampé à 0)
// → tiltX=+1 : spot à droite (x = 0.30 + 0.35 = 0.65)
```

Un `RadialGradient` blanc → transparent centré sur `(cx, cy)`.
Simule un point source de lumière dans la "scène" 3D.

**Passe 3 — Frange chromatique**

La dispersion de la lumière dans le verre donne une frange arc-en-ciel sur les bords.
On la simplifie à deux lignes : une blanche + une de la couleur d'accent.

**Passe 4 — Vignettage**

```dart
RadialGradient(
  colors: [Colors.transparent, Colors.black.withValues(alpha: 0.18)],
  stops: [0.55, 1.0],
)
```

Assombrit les bords pour simuler la courbure d'une surface convexe.
Très subtil mais crucial pour la cohérence visuelle.

---

## 4. Architecture de rebuild — Analyse complète

### Le problème

L'accéléromètre émet 50 événements/seconde.
Sans architecture soigneuse, chaque événement rebuilderait tout l'écran.

**Rebuild complet = ~60 `build()` + relayout + repaint par frame = lag.**

### La solution en 3 niveaux

**Niveau 1 — `ValueNotifier` + `ValueListenableBuilder`**

```dart
// GyroService expose :
final ValueNotifier<GyroState> state = ValueNotifier(GyroState.zero);

// Dans le widget feuille :
ValueListenableBuilder<GyroState>(
  valueListenable: gyroService.state,
  builder: (ctx, gyroState, child) {
    // Seul ce sous-arbre rebuild
    return SpatialWindow(gyroState: gyroState, ...);
  },
)
```

**Niveau 2 — `RepaintBoundary`**

```dart
RepaintBoundary(
  child: SpatialWindow(...), // Layer GPU isolé
)
```

Sans `RepaintBoundary` : quand `SpatialWindow` se repaint,
Flutter remonte dans l'arbre pour trouver le premier ancêtre opaque,
puis repaint tout ce qui est dans ce layer. Avec `RepaintBoundary` :
seul ce widget est dans son propre layer → repaint isolé.

**Niveau 3 — `shouldRepaint` dans les painters**

```dart
@override
bool shouldRepaint(GlassReflectionPainter old) =>
    old.tiltX != tiltX || old.tiltY != tiltY || old.depth != depth;
```

Flutter appelle `shouldRepaint` avant d'appeler `paint()`. Si `false`,
`paint()` n'est jamais appelé → 0 coût GPU pour ce frame.

### Résultat final

| Événement | Widgets qui rebuild |
|-----------|---------------------|
| Tilt gyro (50/sec) | 0 widgets. Seuls les CustomPainters "repaignent" |
| Drag fenêtre | `_WindowsLayer` + 1 `Positioned` |
| Tap (z-order) | `_WindowsLayer` seulement |
| Scintillement étoiles | 1 `CustomPaint` (background) |

---

## 5. Impeller vs Skia — Ce qui change

### BackdropFilter

**Skia :** Blur rendu en 2 passes Gaussian. Coût constant par zone blurée.

**Impeller :** Blur via Metal/Vulkan compute shaders. Plus rapide sur iOS 16+,
mais **nécessite que le calque derrière soit rendu séparément.**

**Implication :** Sans `RepaintBoundary` sur la fenêtre, Impeller doit
capturer tout l'écran pour calculer le blur → coût O(n fenêtres × taille écran).
Avec `RepaintBoundary` : chaque fenêtre ne capte que son rectangle → O(taille fenêtre).

### CustomPainter

**Impeller :** Les gradients `RadialGradient` et `LinearGradient` sont
rendus entièrement sur GPU via des shaders précalculés.
`canvas.drawCircle` avec un gradient shader = une seule passe GPU.

**À éviter avec Impeller :**
- `MaskFilter.blur` avec un grand sigma (>15px) → rend sur CPU dans certains cas
- `canvas.saveLayer()` excessif → crée des layers intermédiaires coûteux
- `Paint.imageFilter` dans un painter → interrompt le render pass Metal

### Vérifier Impeller en debug

```bash
flutter run --enable-impeller          # Force Impeller même sur Android
flutter run --no-enable-impeller       # Force Skia (comparaison)
```

Sur iOS : Impeller est activé par défaut depuis Flutter 3.10.
Sur Android : opt-in via `AndroidManifest.xml` ou flag.

---

## 6. Pièges fréquents et solutions

### Piège 1 : Le `BackdropFilter` qui floute tout

```dart
// ❌ MAUVAIS : blur déborde sur tout l'écran
BackdropFilter(
  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
  child: monContenu,
)

// ✅ BON : blur limité par le ClipRRect
ClipRRect(
  borderRadius: BorderRadius.circular(24),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
    child: const SizedBox.expand(),  // Fond transparent qui déclenche le blur
  ),
)
```

### Piège 2 : Drift du gyroscope

```dart
// ❌ Gyroscope angulaire → drift
gyroscopeEventStream().listen((e) {
  _angleX += e.x * deltaTime; // S'accumule et dérive
});

// ✅ Accéléromètre → inclinaison absolue
accelerometerEventStream().listen((e) {
  _tiltX = e.x / 9.8; // Valeur absolue, stable
});
```

### Piège 3 : setEntry après les rotations

```dart
// ❌ MAUVAIS : la perspective s'applique après les rotations → déformation
Matrix4.identity()
  ..rotateX(0.05)
  ..setEntry(3, 2, 0.0018) // Trop tard
  
// ✅ BON : perspective d'abord, transformations ensuite
Matrix4.identity()
  ..setEntry(3, 2, 0.0018) // En premier
  ..rotateX(0.05)
```

### Piège 4 : ValueNotifier qui notifie inutilement

```dart
// ❌ Notifie même si la valeur n'a pas changé
state.value = GyroState(tiltX: 0.001, tiltY: 0.001);

// ✅ La dead zone évite les notifications à vide
final magnitude = sqrt(dx*dx + dy*dy);
if (magnitude < 0.02) return; // Ne pas notifier
state.value = GyroState(tiltX: _smoothX, tiltY: _smoothY);
```
