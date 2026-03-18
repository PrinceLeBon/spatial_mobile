# 🗺️ Plan d'implémentation — Étape par étape

> Ce plan est conçu pour un développeur intermédiaire qui veut comprendre
> **pourquoi** chaque étape précède la suivante, pas juste **quoi** faire.

---

## Vue d'ensemble

```
Étape 1 → Fond spatial statique
Étape 2 → Fenêtres glassmorphism (statiques)
Étape 3 → Perspective Matrix4 (statique)
Étape 4 → Gyroscope + parallaxe
Étape 5 → Reflets dynamiques (CustomPainter)
Étape 6 → Ombres dynamiques
Étape 7 → Drag & z-order
Étape 8 → Contenus riches des fenêtres
Étape 9 → Polish performance (RepaintBoundary, const)
Étape 10 → Finitions UX
```

---

## Étape 1 — Fond spatial statique

**Objectif :** Avoir un `CustomPaint` qui dessine le fond.

**Ce que tu crées :**
- `SpaceBackgroundPainter` avec fond dégradé + nébuleuses
- Les étoiles sont des `Circle` positionnés aléatoirement
- Le `StaticTickerProvider` drive une `AnimationController` pour le scintillement

**Piège à éviter :**
> ❌ Ne pas regénérer les positions d'étoiles dans `paint()`.
> `paint()` est appelé 60x/sec. Toute génération aléatoire ici = lag garanti.
> ✅ Générer dans le constructeur (ou `initState`) et stocker dans une `List`.

**Validation :** Fond étoilé animé visible, scintillement fluide.

---

## Étape 2 — Fenêtres glassmorphism statiques

**Objectif :** Afficher des fenêtres avec l'effet verre, sans mouvement.

**Ce que tu crées :**
```dart
ClipRRect(
  borderRadius: BorderRadius.circular(24),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
      ),
    ),
  ),
)
```

**Pièges :**
> ❌ `BackdropFilter` sans `ClipRRect` → le blur déborde sur tout l'écran.
> ❌ `BackdropFilter` appliqué à un widget sans fond derrière lui
>    → artefact noir sur Impeller.
> ✅ Toujours avoir un fond animé/coloré DERRIÈRE pour que le blur ait
>    quelque chose à flouter.

**Validation :** Fenêtres semi-transparentes sur le fond étoilé, effet verre visible.

---

## Étape 3 — Perspective Matrix4 (statique)

**Objectif :** Donner une inclinaison 3D fixe aux fenêtres pour valider la perspective.

**Ce que tu crées :**
```dart
Transform(
  alignment: Alignment.center,
  transform: Matrix4.identity()
    ..setEntry(3, 2, 0.0018)  // ← CRUCIAL : active la perspective
    ..rotateX(0.05)            // inclinaison de test (fixe)
    ..rotateY(-0.03),
  child: maFenetre,
)
```

**Explication de `setEntry(3, 2, f)` :**
```
La matrice 4x4 de transformation 3D est :
[ m00 m01 m02 m03 ]
[ m10 m11 m12 m13 ]
[ m20 m21 m22 m23 ]
[ m30 m31 m32 m33 ]

L'entrée [3][2] (ligne 3, colonne 2) = facteur de perspective.
Valeur = 1/focalLength.
0.0018 ≈ 555px de distance focale.
Sans cette valeur → les rotations X/Y sont orthographiques (plates).
Avec cette valeur → les bords semblent "rentrer" dans l'écran.
```

**Piège :**
> ❌ Appliquer la perspective via `Transform.rotate` ou `RotationTransition`
>    → pas de perspective réelle, juste une rotation 2D.
> ✅ Uniquement via `Matrix4` avec `setEntry(3, 2, f)`.

**Validation :** Fenêtres qui semblent avoir une profondeur même sans bouger.

---

## Étape 4 — Gyroscope + parallaxe dynamique

**Objectif :** Connecter l'accéléromètre au mouvement des fenêtres.

**Ce que tu crées :**
- `GyroService` avec filtre EMA
- `ValueNotifier<GyroState>`
- `ValueListenableBuilder` dans le widget fenêtre

**Filtre EMA — pourquoi c'est essentiel :**
```dart
// Sans filtre : valeur brute → tremblements, saccades
// Avec EMA (α=0.08) : réponse lente mais ultra-fluide
_smoothX = 0.08 * rawX + 0.92 * _smoothX;
```

Ajuster α selon l'effet désiré :
| α | Effet |
|---|-------|
| 0.05 | Très lent, presque endormi (belle fluidité) |
| 0.08 | Équilibre réactivité / fluidité (**recommandé**) |
| 0.15 | Réactif mais légèrement saccadé |
| 0.30 | Quasi-instantané, tremble sur les vibrations |

**Parallaxe différentiel :**
```dart
// La clé : les fenêtres proches bougent PLUS que les lointaines
final parallaxFactor = 1.0 - data.depth;
final tx = gyroState.tiltX * 18.0 * parallaxFactor;
```

**Piège :**
> ❌ Même amplitude de parallaxe pour toutes les fenêtres → l'illusion de
>    profondeur disparaît complètement. Tout semble "collé" au même plan.
> ✅ Amplitude proportionnelle à `(1 - depth)` → les proches bougent fort,
>    les lointaines bougent peu.

**Validation :** Inclinaison du téléphone → fenêtres se décalent naturellement
avec une sensation de profondeur crédible.

---

## Étape 5 — Reflets dynamiques (CustomPainter)

**Objectif :** Le `GlassReflectionPainter` suit l'inclinaison.

**Ce que tu crées :**
```dart
// Dans paint() :
final cx = size.width * (0.30 + tiltX * 0.35); // spot qui suit le tilt
final cy = size.height * (0.20 + tiltY * 0.20);

final paint = Paint()
  ..shader = RadialGradient(...).createShader(
    Rect.fromCircle(center: Offset(cx, cy), radius: radius),
  );
canvas.drawCircle(Offset(cx, cy), radius, paint);
```

**Pourquoi CustomPainter et pas un Container avec gradient ?**
> Un Container avec gradient est un widget Flutter → rebuild à chaque frame
> → `Element.rebuild()` → overhead layout/paint complet.
> Un CustomPainter avec `shouldRepaint` → seulement `canvas.draw*` → ~10x plus rapide.

**`shouldRepaint` strict :**
```dart
@override
bool shouldRepaint(GlassReflectionPainter old) =>
    old.tiltX != tiltX || old.tiltY != tiltY;
// Pas de repaint si les valeurs n'ont pas changé (dead zone du gyro aide ici)
```

**Validation :** Le spot lumineux se déplace sur la surface du verre
quand on incline le téléphone.

---

## Étape 6 — Ombres dynamiques

**Objectif :** Les ombres se déplacent avec l'inclinaison pour renforcer la profondeur.

**Ce que tu crées :**
```dart
BoxShadow(
  color: Colors.black.withValues(alpha: 0.4 + (1-depth)*0.3),
  blurRadius: 20 + (1-depth) * 24,   // fenêtres proches = ombre plus nette
  offset: Offset(
    -tiltX * 12.0 * parallaxFactor,   // oppose à l'inclinaison
    -tiltY * 10.0 * parallaxFactor + 8.0,
  ),
)
```

**Logique physique :**
- Lumière vient d'en haut → ombre en bas (offset Y positif de base)
- Téléphone incliné à droite → ombre va à gauche (offset X négatif si tilt > 0)
- Fenêtre proche → ombre plus intense et définie (blurRadius plus petit)
- Fenêtre lointaine → ombre plus diffuse (blurRadius plus grand)

**Validation :** Ombres qui "glissent" sous les fenêtres lors de l'inclinaison,
renforçant l'impression que les fenêtres flottent réellement.

---

## Étape 7 — Drag & z-order

**Objectif :** Fenêtres déplaçables, celle touchée passe devant.

**Ce que tu crées :**
```dart
GestureDetector(
  onTap: () => controller.bringToFront(data.id),
  onPanUpdate: (d) => controller.updatePosition(data.id, d.delta),
  child: ...,
)
```

**z-order via ordre de la liste :**
```dart
// Stack affiche les enfants dans l'ordre de la liste.
// Dernier = devant. Donc bringToFront() = mettre en dernier.
void bringToFront(String id) {
  final window = _windows.firstWhere((w) => w.id == id);
  final rest = _windows.where((w) => w.id != id).toList();
  _windows = [...rest, window]; // window est maintenant le dernier → devant
}
```

**Piège :**
> ❌ Utiliser `Opacity` ou `IndexedStack` pour le z-order → coûteux.
> ✅ Simplement réordonner la liste du Stack → Flutter gère nativement l'ordre d'affichage.

---

## Étape 8 — Contenus riches des fenêtres

**Objectif :** Chaque fenêtre a un contenu cohérent avec l'univers visuel.

**Ce que tu crées :**
- `MusicWindowContent` : vinyl rotatif (RotationTransition), player controls
- `WeatherWindowContent` : température, icône, données
- `NotifWindowContent` : liste de notifications avec indicateur coloré
- `ClockWindowContent` : affichage heure / date

**Principe :** Chaque contenu est un widget **const-compatible** au maximum.
Les parties animées (`RotationTransition` du vinyl) utilisent leur propre
`AnimationController` local → n'impacte pas les autres fenêtres.

---

## Étape 9 — Polish performance

**Objectif :** S'assurer que l'app tourne à 60-120 FPS sur appareil physique.

**Checklist :**
```
✅ RepaintBoundary autour de chaque SpatialWindow
✅ RepaintBoundary autour de chaque CustomPainter
✅ shouldRepaint strict dans tous les painters
✅ const sur tous les widgets statiques (titres, icônes, etc.)
✅ Dead zone dans GyroService (évite les micro-repaints)
✅ SamplingPeriod.gameInterval (50Hz, pas plus)
✅ Pas de setState() dans le chemin critique gyro
```

Voir [`04_PERFORMANCE.md`](./04_PERFORMANCE.md) pour le détail complet.

---

## Étape 10 — Finitions UX

**Objectif :** Les détails qui font passer de "cool demo" à "niveau produit".

- Fenêtres initialisées à des `depth` différentes visuellement cohérentes
- Animations d'apparition au lancement (fade + scale depuis 0.8)
- Feedback haptique léger au début du drag
- Status bar personnalisé (overlay semi-transparent, non le système)
- Mode immersif (`SystemUiMode.immersiveSticky`)

Voir [`05_BONUS_UX_PREMIUM.md`](./05_BONUS_UX_PREMIUM.md) pour les idées avancées.
