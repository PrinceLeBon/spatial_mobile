import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// Données de gyroscope normalisées et lissées.
///
/// [tiltX] : inclinaison gauche/droite  [-1.0, 1.0]
/// [tiltY] : inclinaison avant/arrière  [-1.0, 1.0]
@immutable
class GyroState {
  const GyroState({this.tiltX = 0.0, this.tiltY = 0.0});

  final double tiltX;
  final double tiltY;

  static const GyroState zero = GyroState();

  @override
  String toString() =>
      'GyroState(tiltX: ${tiltX.toStringAsFixed(3)}, tiltY: ${tiltY.toStringAsFixed(3)})';
}

/// Service gyroscope : lit l'accéléromètre, lisse les données,
/// et expose un [ValueNotifier<GyroState>] pour que l'UI s'abonne
/// sans jamais rebuild plus qu'elle ne le doit.
///
/// ⚠️  On utilise l'ACCÉLÉROMÈTRE (gravity) plutôt que le gyroscope
/// angulaire. Pourquoi ?
/// - Le gyroscope donne une vitesse angulaire → il dérive (drift).
/// - L'accéléromètre mesure la gravité → donne l'inclinaison absolue,
///   parfait pour un effet "levitation" stable.
///
/// Implémentation du lissage : Exponential Moving Average (EMA).
/// Formula : s(t) = α * raw(t) + (1 - α) * s(t-1)
/// α = [SpatialTheme.gyroSmoothFactor] (~0.08) → très fluide.
class GyroService {
  GyroService({double smoothFactor = 0.08}) : _alpha = smoothFactor;

  final double _alpha;

  final ValueNotifier<GyroState> state = ValueNotifier<GyroState>(
    GyroState.zero,
  );

  StreamSubscription<AccelerometerEvent>? _subscription;

  // Valeurs lissées internes
  double _smoothX = 0.0;
  double _smoothY = 0.0;

  // Plage de clamp : au-delà de ±9.8 m/s² on est en chute libre
  static const double _maxAccel = 7.0;

  void start() {
    _subscription?.cancel();
    _subscription =
        accelerometerEventStream(
          samplingPeriod: SensorInterval.gameInterval, // ~50Hz
        ).listen(
          _onAccelerometerEvent,
          onError: (_) {
            // Appareil sans capteur ou permission refusée → on reste à zéro.
          },
        );
  }

  void _onAccelerometerEvent(AccelerometerEvent event) {
    // Normalise dans [-1, 1]. event.x = force sur axe X (inclinaison gauche/droite).
    // On inverse X car sur iOS/Android la convention diffère de l'espace visuel.
    final rawX = (-event.x / _maxAccel).clamp(-1.0, 1.0);
    final rawY = (-event.y / _maxAccel).clamp(-1.0, 1.0);

    // EMA smoothing
    _smoothX = _alpha * rawX + (1.0 - _alpha) * _smoothX;
    _smoothY = _alpha * rawY + (1.0 - _alpha) * _smoothY;

    // Dead zone : ignore les micro-vibrations (<2%)
    final dx = math.sqrt(_smoothX * _smoothX + _smoothY * _smoothY);
    if (dx < 0.02) return;

    state.value = GyroState(tiltX: _smoothX, tiltY: _smoothY);
  }

  void stop() {
    _subscription?.cancel();
    _subscription = null;
  }

  void dispose() {
    stop();
    state.dispose();
  }
}
