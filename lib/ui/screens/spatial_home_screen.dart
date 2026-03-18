import 'package:flutter/material.dart';

import '../../core/spatial_window_data.dart';
import '../../sensors/gyro_service.dart';
import '../../sensors/spatial_windows_controller.dart';
import '../painters/space_background_painter.dart';
import '../windows/spatial_window.dart';
import '../windows/window_contents.dart';

/// [SpatialHomeScreen] — Écran principal.
///
/// ─── Stratégie de rendu ─────────────────────────────────────────────────────
///
/// L'arbre de rebuild est découpé en 3 zones distinctes :
///
/// 1. [_BackgroundLayer] — Écoute le gyroscope ET l'AnimationController.
///    Rebuild toutes les frames (ticker) MAIS c'est isolé via RepaintBoundary.
///    Le parent ne rebuild pas.
///
/// 2. [_WindowsLayer] — Écoute [SpatialWindowsController] (ChangeNotifier).
///    Ne rebuild que lors d'un drag ou changement de z-order.
///    Chaque [SpatialWindow] enfant reçoit le gyroState via ValueListenableBuilder
///    mais n'est pas dans l'arbre de rebuild de _WindowsLayer.
///
/// 3. [_GyroWindowWrapper] — Wrapper fin qui écoute le ValueNotifier et passe
///    le state au SpatialWindow. C'est le plus petit arbre possible qui rebuild.
///
/// ─── Pourquoi cette séparation ? ────────────────────────────────────────────
/// Sans cette architecture, TOUT l'écran rebuilderait ~60x/sec à cause du gyro.
/// Avec cette architecture, seuls les CustomPainters repaignent → ~0 rebuild
/// de widgets Flutter standards par seconde pendant le mouvement.
/// ─────────────────────────────────────────────────────────────────────────────
class SpatialHomeScreen extends StatefulWidget {
  const SpatialHomeScreen({super.key});

  @override
  State<SpatialHomeScreen> createState() => _SpatialHomeScreenState();
}

class _SpatialHomeScreenState extends State<SpatialHomeScreen>
    with TickerProviderStateMixin {
  late final GyroService _gyroService;
  late final SpatialWindowsController _windowsController;
  late final AnimationController _bgAnimController;
  late final AnimationController _launchController;
  late final List<StarData> _stars;

  @override
  void initState() {
    super.initState();
    _gyroService = GyroService();
    _windowsController = SpatialWindowsController();
    _stars = StarData.generate(160);

    // Animation lente pour le scintillement des étoiles (8s loop)
    _bgAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();

    // Animation de lancement : 1400ms, joue une seule fois
    _launchController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();

    _gyroService.start();
  }

  @override
  void dispose() {
    _gyroService.dispose();
    _bgAnimController.dispose();
    _launchController.dispose();
    _windowsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // ── Couche 1 : Fond spatial animé ──────────────────────────────────
          // Le fond fade-in rapidement (0→300ms) pour éviter le flash noir
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _launchController,
              curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
            ),
            child: _BackgroundLayer(
              gyroService: _gyroService,
              bgAnimController: _bgAnimController,
              stars: _stars,
            ),
          ),

          // ── Couche 2 : Fenêtres flottantes ─────────────────────────────────
          _WindowsLayer(
            windowsController: _windowsController,
            gyroService: _gyroService,
            launchController: _launchController,
          ),

          // ── Couche 3 : UI overlay (status bar personnalisé) ─────────────────
          FadeTransition(
            opacity: CurvedAnimation(
              parent: _launchController,
              curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
            ),
            child: const _StatusBar(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Couche fond
// ─────────────────────────────────────────────────────────────────────────────

class _BackgroundLayer extends StatelessWidget {
  const _BackgroundLayer({
    required this.gyroService,
    required this.bgAnimController,
    required this.stars,
  });

  final GyroService gyroService;
  final AnimationController bgAnimController;
  final List<StarData> stars;

  @override
  Widget build(BuildContext context) {
    // Double ValueListenableBuilder pour combiner les deux sources sans créer
    // de State supplémentaire.
    return ValueListenableBuilder<GyroState>(
      valueListenable: gyroService.state,
      builder: (ctx, gyroState, child) {
        return AnimatedBuilder(
          animation: bgAnimController,
          builder: (ctx2, child2) {
            return RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                painter: SpaceBackgroundPainter(
                  tiltX: gyroState.tiltX,
                  tiltY: gyroState.tiltY,
                  animOffset: bgAnimController.value,
                  stars: stars,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Couche fenêtres
// ─────────────────────────────────────────────────────────────────────────────

class _WindowsLayer extends StatelessWidget {
  const _WindowsLayer({
    required this.windowsController,
    required this.gyroService,
    required this.launchController,
  });

  final SpatialWindowsController windowsController;
  final GyroService gyroService;
  final AnimationController launchController;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: windowsController,
      builder: (ctx, child) {
        return Stack(
          children: [
            for (int i = 0; i < windowsController.windows.length; i++)
              Positioned(
                left: windowsController.windows[i].position.dx,
                top: windowsController.windows[i].position.dy,
                // Chaque fenêtre apparaît avec un délai staggeré :
                // fenêtre 0 (lointaine) → commence à t=10%
                // fenêtre 3 (proche)   → commence à t=40%
                // L'intervalle de chaque fenêtre dure 55% de l'animation totale
                child: _LaunchWrapper(
                  launchController: launchController,
                  index: i,
                  child: _GyroWindowWrapper(
                    data: windowsController.windows[i],
                    gyroService: gyroService,
                    onPanUpdate: (delta) => windowsController.updatePosition(
                      windowsController.windows[i].id,
                      delta,
                    ),
                    onTap: () => windowsController.bringToFront(
                      windowsController.windows[i].id,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Applique l'animation de lancement staggerée à une fenêtre.
///
/// Chaque fenêtre (identifiée par [index]) démarre son animation à un moment
/// légèrement différent → effet "cascade" naturel.
///
/// Séquence :
/// - Scale  : 0.82 → 1.0  (fenêtre "sort" vers le spectateur)
/// - Opacity: 0.0  → 1.0
/// - Blur   : translateY de +20px → 0 (fenêtres arrivent par le bas)
///
/// Interval(start, end) : [0.0, 1.0] représente toute la durée du controller.
class _LaunchWrapper extends StatelessWidget {
  const _LaunchWrapper({
    required this.launchController,
    required this.index,
    required this.child,
  });

  final AnimationController launchController;
  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Stagger : 4 fenêtres, chacune démarre 10% plus tard.
    // Interval : chaque animation couvre 55% de la durée totale.
    final start = index * 0.10;
    final end = (start + 0.55).clamp(0.0, 1.0);

    final curve = CurvedAnimation(
      parent: launchController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );

    return AnimatedBuilder(
      animation: curve,
      builder: (context, child) {
        final v = curve.value; // [0.0 → 1.0]
        return Opacity(
          opacity: v,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.0018)
              // Fenêtres arrivent légèrement du bas et de loin
              ..translateByDouble(0, (1.0 - v) * 24.0, 0, 1.0)
              ..scaleByDouble(
                0.82 + v * 0.18, // 0.82 → 1.0
                0.82 + v * 0.18,
                1.0,
                1.0,
              ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

/// Wrapper minimal qui souscrit au ValueNotifier gyro et
/// reconstruit UNIQUEMENT le SpatialWindow concerné.
class _GyroWindowWrapper extends StatelessWidget {
  const _GyroWindowWrapper({
    required this.data,
    required this.gyroService,
    required this.onPanUpdate,
    required this.onTap,
  });

  final SpatialWindowData data;
  final GyroService gyroService;
  final void Function(Offset) onPanUpdate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<GyroState>(
      valueListenable: gyroService.state,
      builder: (context, gyroState, child) {
        return SpatialWindow(
          data: data,
          gyroState: gyroState,
          onPanUpdate: onPanUpdate,
          onTap: onTap,
          child: _windowContent(data.id),
        );
      },
    );
  }

  Widget _windowContent(String id) {
    return switch (id) {
      'music' => const MusicWindowContent(),
      'weather' => const WeatherWindowContent(),
      'notif' => const NotifWindowContent(),
      'clock' => const ClockWindowContent(),
      _ => const SizedBox.shrink(),
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Status bar overlay
// ─────────────────────────────────────────────────────────────────────────────

class _StatusBar extends StatelessWidget {
  const _StatusBar();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Spatial Mobile',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2,
                ),
              ),
              Row(
                children: [
                  Icon(
                    Icons.signal_cellular_alt,
                    color: Colors.white.withValues(alpha: 0.45),
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    Icons.wifi,
                    color: Colors.white.withValues(alpha: 0.45),
                    size: 14,
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    Icons.battery_full,
                    color: Colors.white.withValues(alpha: 0.45),
                    size: 14,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
