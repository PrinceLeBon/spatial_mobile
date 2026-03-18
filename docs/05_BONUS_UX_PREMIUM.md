# ✨ Bonus — UX Premium & Améliorations avancées

> Ces idées sont ce qui sépare une "bonne démo" d'une "démo de conférence".
> Chacune est actionnable, avec une estimation de complexité.

---

## 1. Spring animation sur le parallaxe

### Problème actuel
Le filtre EMA donne une réponse fluide mais **linéaire** dans son comportement.
En vrai physique, un objet suspendu a un comportement ressort : il dépasse
légèrement sa position cible, puis revient (overshooting).

### Solution : `SpringSimulation`

```dart
import 'package:flutter/physics.dart';

// Dans GyroService, remplacer le EMA par une simulation physique :
final _springDesc = const SpringDescription(
  mass: 1.0,
  stiffness: 80.0,   // Raideur : plus haut = plus réactif
  damping: 12.0,     // Amortissement : plus haut = moins d'oscillations
);

// Dans un AnimationController avec TickerProvider :
void _animateTo(double target) {
  final simulation = SpringSimulation(_springDesc, current, target, velocity);
  _controller.animateWith(simulation);
}
```

**Résultat :** Quand on incline rapidement, les fenêtres "dépassent" légèrement
puis reviennent. Exactement comme une suspension physique. Effet premium garanti.

**Complexité :** 🟡 Moyenne (3-4h)

---

## 2. Fragment Shaders custom (Flutter 3.10+)

### Pour quoi faire ?
Les reflets de verre actuels sont des approximations géométriques (gradients).
Un vrai effet de caustic (motifs de lumière sur verre) nécessite un shader GLSL.

### Exemple de shader de base

```glsl
// assets/shaders/glass_caustic.frag
#include <flutter/runtime_effect.glsl>

uniform sampler2D uTexture;
uniform vec2 uResolution;
uniform float uTiltX;
uniform float uTiltY;
uniform float uTime;

out vec4 fragColor;

void main() {
  vec2 uv = FlutterFragCoord().xy / uResolution;
  
  // Distorsion de l'UV basée sur le tilt → effet réfraction
  float dist = sin(uv.x * 8.0 + uTime) * 0.02 * uTiltX;
  uv.y += dist;
  
  vec4 color = texture(uTexture, uv);
  fragColor = color;
}
```

```dart
// Utilisation dans Flutter
final shader = await FragmentProgram.fromAsset('assets/shaders/glass_caustic.frag');
final paint = Paint()..shader = shader.fragmentShader()
  ..setFloat(0, tiltX)
  ..setFloat(1, tiltY);
```

**Résultat :** Motifs de lumière ondulants sur les surfaces de verre.
Effet unique, impossible à reproduire avec des widgets Flutter standards.

**Complexité :** 🔴 Élevée (1-2 jours, nécessite connaissances GLSL)

---

## 3. Drag avec momentum (inertie post-drag)

### Problème actuel
Quand on lâche une fenêtre après un drag, elle s'arrête instantanément.
En visionOS, les fenêtres continuent sur leur lancée puis freinent doucement.

### Solution : `VelocityTracker` + `FrictionSimulation`

```dart
// Dans GestureDetector :
final _velocityTracker = VelocityTracker.withKind(PointerDeviceKind.touch);

onPanUpdate: (d) {
  _velocityTracker.addPosition(d.sourceTimeStamp!, d.localPosition);
  controller.updatePosition(data.id, d.delta);
},

onPanEnd: (d) {
  final velocity = _velocityTracker.getVelocity();
  _startInertia(velocity.pixelsPerSecond);
},

void _startInertia(Offset velocity) {
  // FrictionSimulation : décélère exponentiellement
  final simX = FrictionSimulation(0.135, position.dx, velocity.dx);
  final simY = FrictionSimulation(0.135, position.dy, velocity.dy);
  
  _inertiaController.animateWith(simX); // Anime X
  // Idem pour Y en parallèle
}
```

**Résultat :** Les fenêtres "glissent" après le lâcher. Sensation physique
identique au scroll iOS. Extrêmement satisfaisant à utiliser.

**Complexité :** 🟡 Moyenne (4-6h)

---

## 4. Apparition au démarrage (Launch animation)

### Pourquoi c'est important
La première impression est critique. Une app qui "pop" brutalement n'est pas premium.
Les fenêtres doivent apparaître avec une animation d'entrée soigneuse.

### Séquence recommandée

```
t=0ms  : Fond spatial apparaît (fade in 400ms)
t=200ms: Fenêtre 1 (lointaine) scale 0.85→1.0 + fade (600ms, curve: easeOut)
t=300ms: Fenêtre 2 → idem avec 100ms de délai
t=400ms: Fenêtre 3 → idem
t=500ms: Fenêtre 4 (proche) → last, elle "sort" vers le spectateur
```

**Stagger effect :**
```dart
AnimationController _launchController; // duration: 1200ms

// Pour chaque fenêtre i :
final start = 0.15 * i; // 0.0, 0.15, 0.30, 0.45
final end   = start + 0.55;
final anim  = CurvedAnimation(
  parent: _launchController,
  curve: Interval(start, end, curve: Curves.easeOutCubic),
);

// Appliquer :
ScaleTransition(scale: Tween(begin: 0.85, end: 1.0).animate(anim), ...)
FadeTransition(opacity: Tween(begin: 0.0, end: 1.0).animate(anim), ...)
```

**Complexité :** 🟢 Faible (2-3h)

---

## 5. Haptic feedback contextuel

### Règle d'or Apple
> "Le feedback haptique doit confirmer une action, pas l'annoncer."

```dart
import 'package:flutter/services.dart';

// Au début du drag (fenêtre "saisie")
onPanStart: (_) => HapticFeedback.selectionClick(),

// Quand une fenêtre passe devant une autre (z-order change)
onTap: () {
  controller.bringToFront(data.id);
  HapticFeedback.lightImpact(); // Léger "clic"
}

// Feedback différencié selon la profondeur :
// Fenêtre proche (depth < 0.3) → lightImpact
// Fenêtre lointaine (depth > 0.5) → selectionClick (plus doux)
```

**Complexité :** 🟢 Très faible (30min)

---

## 6. Effet "focus depth" au tap

### Idée
Quand on tap une fenêtre, elle "avance" vers le spectateur :
- `depth` diminue temporairement (ex: 0.65 → 0.15)
- Blur réduit, scale augmente, ombre plus nette
- Animation 300ms ease-out, puis retour automatique après 2s

```dart
void _onWindowFocused(String id) {
  final window = _windows.firstWhere((w) => w.id == id);
  
  // Animer vers depth=0.15
  _animateDepth(id, from: window.depth, to: 0.15, duration: 300ms);
  
  // Retour après 2s
  Future.delayed(Duration(seconds: 2), () {
    _animateDepth(id, from: 0.15, to: window.depth, duration: 400ms);
  });
}
```

**Résultat :** La fenêtre "vient vers vous" quand vous la touchez.
Renforce massivement l'illusion de profondeur.

**Complexité :** 🟡 Moyenne (3-4h, nécessite d'animer depth dans le modèle)

---

## 7. Ambient occlusion simulée

### Qu'est-ce que l'AO ?
En rendu 3D, l'occlusion ambiante assombrit les zones où deux surfaces
sont proches. Sur des fenêtres flottantes, si deux fenêtres se superposent,
la partie "couverte" devrait être plus sombre.

### Simulation Flutter

```dart
// Dans spatial_window.dart, calculer la superposition avec les voisins :
// (passé en paramètre depuis SpatialWindowsController)
final overlappingDepth = _computeOverlapWithNeighbors(data, allWindows);

// Assombrir le fond verre proportionnellement
final aoOpacity = glassOpacity - overlappingDepth * 0.04;
```

**Complexité :** 🔴 Élevée (nécessite de passer les données de voisinage dans le widget)

---

## 8. Détails UX qui font vraiment la différence

Ces micro-détails sont invisibles individuellement mais créent une sensation
de "polish" qui différencie un produit amateur d'un produit professionnel.

### Typographie

```dart
// ✅ Hiérarchie stricte : 3 niveaux seulement
// Niveau 1 : Titre fenêtre → Inter 600, 12px, +0.3 letter-spacing
// Niveau 2 : Contenu principal → Inter 700, 13px
// Niveau 3 : Metadata → Inter 400, 10px, 55% opacity
```

### Coins arrondis cohérents

```
Fenêtre : 24px de rayon
Éléments internes : 10-12px
Boutons : 8px ou full circle
Indicateurs : circle
```
Jamais des rayons aléatoires. La cohérence géométrique = professionnalisme.

### Opacités en paliers définis

```dart
// ✅ Utiliser des paliers fixes, pas des valeurs arbitraires
static const double textPrimary    = 0.95; // ~F2
static const double textSecondary  = 0.60; // ~99
static const double textTertiary   = 0.33; // ~55
static const double borderLight    = 0.18; // ~2E
static const double borderSubtle   = 0.08; // ~14
```

### Absence de couleur pure

```dart
// ❌ Blanc pur → casse l'illusion de profondeur
Colors.white

// ✅ Blanc légèrement teinté de bleu (comme un écran lumineux)
const Color(0xF2F4F8FF) // 95% blanc légèrement bleuté
```

### Taille de police pour les données chiffrées

```dart
// Les grandes valeurs numériques (température, heure) en weight ULTRA-LIGHT
// C'est une signature Apple/visionOS très reconnaissable
GoogleFonts.inter(fontSize: 44, fontWeight: FontWeight.w100)
// → Donne un aspect "instrument de mesure de précision"
```

---

## 9. Idée avancée : Depth Map dynamique

### Concept
Au lieu de `depth` fixe par fenêtre, calculer la profondeur relative
des fenêtres en temps réel en fonction de leur superposition visuelle.

Les fenêtres qui se superposent beaucoup → plus d'écart de depth automatique
→ l'espace 3D se "déploie" pour éviter les conflits visuels.

C'est un système d'**auto-organisation spatiale** similaire à ce que
fait visionOS nativement avec son depth manager.

**Complexité :** 🔴 Très élevée (système complet à implémenter)

---

## Priorisation recommandée

| Priorité | Amélioration | Impact visuel | Effort |
|----------|-------------|---------------|--------|
| 1 | Launch animation (stagger) | ⭐⭐⭐⭐⭐ | 🟢 Faible |
| 2 | Haptic feedback | ⭐⭐⭐ | 🟢 Très faible |
| 3 | Spring animation | ⭐⭐⭐⭐ | 🟡 Moyenne |
| 4 | Drag avec momentum | ⭐⭐⭐⭐ | 🟡 Moyenne |
| 5 | Focus depth au tap | ⭐⭐⭐⭐ | 🟡 Moyenne |
| 6 | Fragment shaders | ⭐⭐⭐⭐⭐ | 🔴 Élevée |
