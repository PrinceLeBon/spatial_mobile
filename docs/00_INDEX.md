# 📚 Spatial Mobile — Documentation Technique

> Application Flutter simulant une interface spatiale (visionOS-inspired) avec
> profondeur visuelle, glassmorphism avancé, parallaxe gyroscopique et effets de
> verre dynamiques.

---

## Table des matières

| # | Fichier | Contenu |
|---|---------|---------|
| 1 | [`01_ARCHITECTURE.md`](./01_ARCHITECTURE.md) | Structure du projet, rôle de chaque fichier, flux de données |
| 2 | [`02_IMPLEMENTATION_PLAN.md`](./02_IMPLEMENTATION_PLAN.md) | Plan étape par étape : du setup au polish final |
| 3 | [`03_TECHNICAL_DEEP_DIVE.md`](./03_TECHNICAL_DEEP_DIVE.md) | Explications techniques : Matrix4, gyro, glassmorphism, painters |
| 4 | [`04_PERFORMANCE.md`](./04_PERFORMANCE.md) | Optimisation Impeller/Skia, rebuild budget, BackdropFilter |
| 5 | [`05_BONUS_UX_PREMIUM.md`](./05_BONUS_UX_PREMIUM.md) | Idées avancées, détails UX qui font la différence |

---

## Prérequis

- Flutter ≥ 3.24 (Impeller activé par défaut sur iOS)
- Dart ≥ 3.4
- Dépendances : `sensors_plus`, `google_fonts`
- Appareil physique recommandé (gyroscope requis)

---

## Lancer le projet

```bash
flutter pub get
flutter run --release   # Release pour mesurer les vraies perfs
```

> ⚠️ Toujours tester en **release** pour les benchmarks de performance.
> Le mode debug désactive plusieurs optimisations Impeller.
