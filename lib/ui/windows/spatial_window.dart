import 'dart:ui';
import 'package:flutter/material.dart';

import '../../core/spatial_theme.dart';
import '../../core/spatial_window_data.dart';
import '../../sensors/gyro_service.dart';
import '../painters/glass_reflection_painter.dart';

/// [SpatialWindow] — Fenêtre flottante avec :
///
/// • Glassmorphism : BackdropFilter (blur) + fond semi-transparent
/// • Parallaxe dynamique : Transform.translate + légère rotation 3D
///   via Matrix4, piloté par [GyroState]
/// • Reflets dynamiques : [GlassReflectionPainter] via CustomPaint
/// • Ombre réaliste : BoxShadow qui se décale selon l'inclinaison
/// • Drag : GestureDetector onPanUpdate
///
/// ─── Architecture de rebuild ─────────────────────────────────────────────────
/// • [SpatialWindow] écoute [GyroService.state] via [ValueListenableBuilder].
///   Seul le sous-arbre DANS le builder rebuild → le parent ne rebuild jamais
///   pour un simple changement de tilt.
/// • La position de drag passe par le [SpatialWindowsController] (ChangeNotifier)
///   → notifie uniquement les widgets qui écoutent.
/// • [RepaintBoundary] isole le CustomPainter dans son propre layer Skia/Impeller.
/// ─────────────────────────────────────────────────────────────────────────────
class SpatialWindow extends StatelessWidget {
  const SpatialWindow({
    super.key,
    required this.data,
    required this.gyroState,
    required this.onPanUpdate,
    required this.onTap,
    required this.child,
  });

  final SpatialWindowData data;

  /// L'état du gyroscope est passé depuis le parent qui écoute le ValueNotifier.
  /// Le widget lui-même est STATELESS → pas de setState() ici.
  final GyroState gyroState;

  final void Function(Offset delta) onPanUpdate;
  final VoidCallback onTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    // ── Calcul des transformations parallaxe ────────────────────────────────
    // Les fenêtres lointaines bougent MOINS (elles sont "fixées" dans l'espace)
    // Les fenêtres proches bougent PLUS (effet de profondeur réaliste)
    final parallaxFactor = 1.0 - data.depth; // proche = 1.0, loin = 0.35
    final tx =
        gyroState.tiltX * SpatialTheme.parallaxAmplitude * parallaxFactor;
    final ty =
        gyroState.tiltY * SpatialTheme.parallaxAmplitude * parallaxFactor;

    // Rotation 3D légère : inclinaison donne une rotation autour de Y et X
    final rotX =
        -gyroState.tiltY *
        SpatialTheme.parallaxRotationAmplitude *
        parallaxFactor;
    final rotY =
        gyroState.tiltX *
        SpatialTheme.parallaxRotationAmplitude *
        parallaxFactor;

    // ── Ombres dynamiques ───────────────────────────────────────────────────
    // L'ombre se décale dans la direction opposée à l'inclinaison
    // Plus la fenêtre est proche, plus l'ombre est intense et définie
    final shadowBlur = 20.0 + (1.0 - data.depth) * 24.0;
    final shadowOpacity = 0.35 + (1.0 - data.depth) * 0.3;
    final shadowOffsetX = -gyroState.tiltX * 12.0 * parallaxFactor;
    final shadowOffsetY = -gyroState.tiltY * 10.0 * parallaxFactor + 8.0;

    return GestureDetector(
      onTap: onTap,
      onPanUpdate: (d) => onPanUpdate(d.delta),
      child: Transform(
        alignment: Alignment.center,
        transform: _buildMatrix(tx, ty, rotX, rotY, data.depthScale),
        child: RepaintBoundary(
          // RepaintBoundary : cette fenêtre est isolée dans son propre layer.
          // Quand le tilt change → seule cette fenêtre repaint, pas les autres.
          child: Container(
            width: data.size.width,
            height: data.size.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(
                SpatialTheme.windowBorderRadius,
              ),
              boxShadow: [
                // Ombre principale (profonde)
                BoxShadow(
                  color: SpatialTheme.shadowColor.withValues(
                    alpha: shadowOpacity,
                  ),
                  blurRadius: shadowBlur,
                  offset: Offset(shadowOffsetX, shadowOffsetY),
                  spreadRadius: -4,
                ),
                // Halo coloré de l'accent (glow)
                BoxShadow(
                  color: data.accentColor.withValues(
                    alpha: 0.18 * (1.0 - data.depth),
                  ),
                  blurRadius: shadowBlur * 1.5,
                  offset: Offset(shadowOffsetX * 0.5, shadowOffsetY * 0.5),
                  spreadRadius: -8,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                SpatialTheme.windowBorderRadius,
              ),
              child: Stack(
                children: [
                  // ── Couche 1 : Blur de l'arrière-plan ────────────────────
                  // BackdropFilter est coûteux GPU. RepaintBoundary ci-dessus
                  // l'isole → seule la zone de la fenêtre est reblurée.
                  BackdropFilter(
                    filter: ImageFilter.blur(
                      sigmaX: data.blurSigma,
                      sigmaY: data.blurSigma,
                      // tileMode.clamp évite les artefacts aux bords
                    ),
                    child: const SizedBox.expand(),
                  ),

                  // ── Couche 2 : Fond verre teinté ─────────────────────────
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: data.glassOpacity),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(
                            alpha: data.glassOpacity + 0.04,
                          ),
                          data.accentColor.withValues(alpha: 0.06),
                          Colors.white.withValues(
                            alpha: data.glassOpacity - 0.02,
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── Couche 3 : Contenu de la fenêtre ─────────────────────
                  Padding(padding: const EdgeInsets.all(0), child: child),

                  // ── Couche 4 : Reflets dynamiques (CustomPainter) ─────────
                  // RepaintBoundary interne → le painter ne déclenche pas
                  // de repaint du contenu quand le tilt change.
                  RepaintBoundary(
                    child: CustomPaint(
                      size: data.size,
                      painter: GlassReflectionPainter(
                        tiltX: gyroState.tiltX,
                        tiltY: gyroState.tiltY,
                        accentColor: data.accentColor,
                        borderRadius: SpatialTheme.windowBorderRadius,
                        depth: data.depth,
                      ),
                    ),
                  ),

                  // ── Couche 5 : Bordure externe ────────────────────────────
                  IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          SpatialTheme.windowBorderRadius,
                        ),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                          width: 0.8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Construit une Matrix4 avec :
  /// - Translation (tx, ty) pour le parallaxe 2D
  /// - RotateX et RotateY pour la perspective 3D légère
  /// - Scale pour la profondeur
  /// - setEntry(3, 2, perspectiveFactor) pour la vraie projection perspective
  Matrix4 _buildMatrix(
    double tx,
    double ty,
    double rotX,
    double rotY,
    double scale,
  ) {
    return Matrix4.identity()
      // La ligne magique : active la projection perspective.
      // setEntry(row, col, value) → entry [3][2] = 1/distance_focale
      // 0.0018 ≈ distance focale de ~555px → effet subtil et crédible
      ..setEntry(3, 2, SpatialTheme.perspectiveFactor)
      ..translateByDouble(tx, ty, 0.0, 1.0)
      ..rotateX(rotX)
      ..rotateY(rotY)
      ..scaleByDouble(scale, scale, 1.0, 1.0);
  }
}
