# ⚡ Performance — Guide complet

> Objectif : 60–120 FPS constants sur appareil physique, même avec
> 4 BackdropFilters simultanés + gyroscope à 50Hz.

---

## 1. Budget de performance

### Ce qui coûte cher (GPU)

| Opération | Coût relatif | Notes |
|-----------|-------------|-------|
| `BackdropFilter` blur | ⚠️ Élevé | Dépend de la taille et du sigma |
| `RadialGradient` large | 🟡 Moyen | Optimisé par Impeller |
| `canvas.drawCircle` x160 | 🟢 Faible | Batché par le GPU |
| `BoxShadow` multiple | 🟡 Moyen | Chaque shadow = 1 texture |
| `ImageFilter` dans painter | ⚠️ Élevé | Éviter si possible |

### Ce qui coûte cher (CPU / Dart)

| Opération | Coût relatif | Notes |
|-----------|-------------|-------|
| `setState()` dans le chemin gyro | ⚠️ INTERDIT | Rebuild widget tree |
| Calcul aléatoire dans `paint()` | ⚠️ INTERDIT | Chaque frame = lag |
| `List.generate` dans `build()` | 🟡 Moyen | Déplacer dans `initState` |
| `BoxDecoration` sans `const` | 🟡 Moyen | Crée un objet par rebuild |

---

## 2. RepaintBoundary — Guide d'utilisation

### Principe

`RepaintBoundary` crée un **layer GPU isolé**. Le widget à l'intérieur est
rendu dans une texture séparée, puis composée avec le reste.

**Avantage :** Si seul ce widget change, seul ce layer est re-rendu sur GPU.
**Coût :** Chaque `RepaintBoundary` = 1 texture supplémentaire en mémoire GPU.

### Où en mettre

```
✅ Autour de chaque SpatialWindow   → isole le BackdropFilter
✅ Autour de chaque CustomPainter   → isole les repaints du painter
✅ Autour du fond étoilé            → le fond repaint indépendamment
❌ Pas autour de chaque widget leaf → surcharge mémoire sans bénéfice
```

### Règle pratique

> Mettre un `RepaintBoundary` si et seulement si :
> 1. Ce widget change souvent ET
> 2. Ce widget est isolable visuellement (pas de transparence qui dépend du parent)

### Vérifier l'effet avec Flutter DevTools

```bash
flutter run --profile
# Ouvrir DevTools → "Performance" → activer "Show repaint rainbow"
# Les zones qui changent de couleur = zones qui repaignent
```

---

## 3. BackdropFilter — Optimisation GPU

### Le problème

`BackdropFilter` capture tout ce qui est **derrière** dans le même layer,
applique le filtre, et re-composite. Si plusieurs fenêtres sont dans le même layer :

```
Sans RepaintBoundary :
  Fenêtre A blur → capture fond + fenêtre B + fenêtre C → coûteux
  
Avec RepaintBoundary sur chaque fenêtre :
  Fenêtre A blur → capture seulement le layer inférieur → rapide
```

### Sigma optimal

```dart
// Trop faible (< 10) → effet verre peu crédible
// Trop fort (> 40) → performances dégradées sur anciens appareils
// Recommandé : 20-30 (selon la profondeur)
double get blurSigma => 20.0 + depth * 14.0; // [20, 34]
```

### Éviter le "black flash" sur Impeller

Sur Impeller, si le widget derrière le `BackdropFilter` n'est pas encore rendu,
le blur capture du noir → flash noir au démarrage.

**Solution :**
```dart
// Donner un fond opaque à l'écran principal
Scaffold(
  backgroundColor: Colors.black, // ← Jamais Colors.transparent
  body: Stack([...]),
)
```

---

## 4. Séparation logique / UI — Impact performance

### Mauvais pattern (setState dans le chemin gyro)

```dart
// ❌ Ceci rebuilde TOUT le widget et ses enfants 50x/sec
class _BadWindow extends StatefulWidget {
  @override
  State<_BadWindow> createState() => _BadWindowState();
}
class _BadWindowState extends State<_BadWindow> {
  double _tiltX = 0;
  
  @override
  void initState() {
    gyroStream.listen((e) {
      setState(() => _tiltX = e.x); // ← PROBLÈME
    });
  }
}
```

**Conséquences :**
- `build()` appelé 50x/sec
- Tous les enfants rebuilt même s'ils sont const
- Layout recalculé
- Paint déclenché sur le layer complet

### Bon pattern (ValueNotifier + builder minimal)

```dart
// ✅ Seul le Transform rebuild, rien d'autre
ValueListenableBuilder<GyroState>(
  valueListenable: gyroService.state,
  builder: (ctx, gyroState, child) {
    // ← "child" est le sous-arbre statique (ne rebuild pas)
    return Transform(
      transform: _buildMatrix(gyroState.tiltX, gyroState.tiltY),
      child: child, // ← déjà construit, réutilisé
    );
  },
  child: const _StaticWindowContent(), // ← const, construit 1 seule fois
)
```

**Gain :** Le `child` statique est construit une seule fois au démarrage.
À chaque frame, seul le `Transform` est recomputé (opération O(1)).

---

## 5. const widgets — Impact concret

### Pourquoi const aide

```dart
// ❌ Crée un nouvel objet Icon à chaque rebuild
Icon(Icons.cloud, color: Colors.white)

// ✅ L'objet est partagé, Dart ne crée rien
const Icon(Icons.cloud, color: Colors.white)
```

Flutter compare les widgets par identité (`identical()`) pour le diffing.
Si `identical(oldWidget, newWidget)` → skip de tout le sous-arbre.
Avec `const`, tous les widgets identiques partagent la même instance.

### Checklist const dans ce projet

```dart
✅ SpatialWindowTitleBar   → const (couleurs passées en params const)
✅ _TrafficLight           → const
✅ _StatusBar              → const
✅ ClockWindowContent      → const (contenu statique)
✅ WeatherWindowContent    → const
✅ NotifWindowContent      → const
⚠️ MusicWindowContent     → StatefulWidget (vinyl animé)
```

---

## 6. AnimationController — Bonnes pratiques

### Un seul controller pour le fond

```dart
// ✅ UN seul AnimationController pour tout le fond étoilé
// (pas un par étoile)
_bgAnimController = AnimationController(
  vsync: this,
  duration: const Duration(seconds: 8),
)..repeat();
```

Le scintillement individuel de chaque étoile est géré via sa propriété `phase` :
```dart
final pulse = sin(animOffset * 2π + star.phase);
// animOffset = même valeur pour toutes les étoiles (1 controller)
// star.phase = décalage individuel (0 à 2π)
// → chaque étoile scintille à une fréquence légèrement différente
```

**50 controllers d'animation = 50 Tickers = overhead CPU significatif.**
**1 controller + phase offset = identique visuellement, 1 Ticker.**

### Dispose systématique

```dart
@override
void dispose() {
  _gyroService.dispose();         // Annule le StreamSubscription
  _bgAnimController.dispose();    // Stoppe le Ticker
  _windowsController.dispose();   // Annule les listeners ChangeNotifier
  super.dispose();
}
```

Oublier un `dispose()` = fuite mémoire + Ticker qui continue après unmount.

---

## 7. Mesurer les performances

### Avec Flutter DevTools

```bash
# Lancer en profile mode
flutter run --profile

# Ouvrir DevTools depuis VS Code ou IntelliJ
# Onglet "Performance" :
#   - UI thread : temps Dart (build, layout)
#   - Raster thread : temps GPU (paint, composite)
# Objectif : les deux sous 8ms pour 120FPS, sous 16ms pour 60FPS
```

### Métriques cibles

| Métrique | Cible 60FPS | Cible 120FPS |
|----------|-------------|--------------|
| UI thread par frame | < 16ms | < 8ms |
| Raster thread par frame | < 16ms | < 8ms |
| Widgets rebuilt/frame (gyro) | 0 | 0 |
| Layers GPU | ~7 (fond + 4 fenêtres + painters) | idem |

### Indicateur visuel rapide

```dart
// Dans MaterialApp
showPerformanceOverlay: true, // Barres vertes/rouges en haut
```

Rouge = frame > 16ms. Si rouge → identifier avec DevTools.

---

## 8. iOS vs Android — Différences

### iOS (Impeller par défaut)

- BackdropFilter = Metal compute shader → très rapide
- `BlurStyle.normal` dans `MaskFilter` → GPU-accelerated
- `canvas.drawShadow` → rendu natif CoreAnimation

### Android (Skia ou Impeller opt-in)

- BackdropFilter = 2 passes Gaussian Skia → plus lent sur GPU Vulkan limité
- Recommandation : réduire `blurSigma` de 20% sur Android si besoin
- Activer Impeller Android : `AndroidManifest.xml` :

```xml
<meta-data
    android:name="io.flutter.embedding.android.EnableImpeller"
    android:value="true" />
```

### Adaptation dynamique

```dart
// Détecter la plateforme et adapter le sigma
import 'dart:io';

double get blurSigma {
  final base = 20.0 + depth * 14.0;
  return Platform.isAndroid ? base * 0.75 : base;
}
```
