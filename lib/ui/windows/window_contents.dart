import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/spatial_theme.dart';
import '../../sensors/spatial_windows_controller.dart';
import '../widgets/spatial_title_bar.dart';

/// Contenu de la fenêtre Music Player
class MusicWindowContent extends StatefulWidget {
  const MusicWindowContent({super.key});

  @override
  State<MusicWindowContent> createState() => _MusicWindowContentState();
}

class _MusicWindowContentState extends State<MusicWindowContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _vinylController;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _vinylController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
  }

  void _togglePlay() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _vinylController.repeat();
      } else {
        _vinylController.stop();
      }
    });
  }

  @override
  void dispose() {
    _vinylController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SpatialWindowTitleBar(
          title: 'Music',
          icon: kMusicIcon,
          accentColor: SpatialTheme.accentMusic,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
            child: Row(
              children: [
                // Vinyl rotatif
                RotationTransition(
                  turns: _vinylController,
                  child: _VinylDisc(accentColor: SpatialTheme.accentMusic),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Interstellar',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: SpatialTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Hans Zimmer',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: SpatialTheme.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Barre de progression
                      _ProgressBar(accentColor: SpatialTheme.accentMusic),
                      const SizedBox(height: 8),
                      // Contrôles
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _ControlBtn(
                            icon: Icons.skip_previous_rounded,
                            onTap: () {},
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _togglePlay,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: SpatialTheme.accentMusic.withValues(
                                  alpha: 0.8,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: SpatialTheme.accentMusic.withValues(
                                      alpha: 0.5,
                                    ),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _isPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ControlBtn(
                            icon: Icons.skip_next_rounded,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _VinylDisc extends StatelessWidget {
  const _VinylDisc({required this.accentColor});
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.15),
            accentColor.withValues(alpha: 0.4),
            Colors.black.withValues(alpha: 0.7),
            accentColor.withValues(alpha: 0.3),
            Colors.black.withValues(alpha: 0.8),
          ],
          stops: const [0.0, 0.08, 0.35, 0.55, 1.0],
        ),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.35),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Center(
        child: Container(
          width: 12,
          height: 12,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Color(0xFF1A1A2E),
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.accentColor});
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 2.5,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        FractionallySizedBox(
          widthFactor: 0.42,
          child: Container(
            height: 2.5,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.6),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ControlBtn extends StatelessWidget {
  const _ControlBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, color: SpatialTheme.textSecondary, size: 18),
    );
  }
}

// ── Fenêtre Météo ────────────────────────────────────────────────────────────

class WeatherWindowContent extends StatelessWidget {
  const WeatherWindowContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SpatialWindowTitleBar(
          title: 'Météo',
          icon: kWeatherIcon,
          accentColor: SpatialTheme.accentWeather,
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Paris',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: SpatialTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '18°',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: SpatialTheme.textPrimary,
                          fontSize: 42,
                          fontWeight: FontWeight.w200,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'Partiellement nuageux',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          color: SpatialTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.cloud_outlined,
                      color: SpatialTheme.accentWeather,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    _WeatherRow(
                      icon: Icons.water_drop_outlined,
                      label: '72%',
                      color: SpatialTheme.accentWeather,
                    ),
                    _WeatherRow(
                      icon: Icons.air,
                      label: '14 km/h',
                      color: SpatialTheme.accentWeather,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _WeatherRow extends StatelessWidget {
  const _WeatherRow({
    required this.icon,
    required this.label,
    required this.color,
  });
  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color.withValues(alpha: 0.7), size: 10),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Inter',
            color: SpatialTheme.textSecondary,
            fontSize: 9,
          ),
        ),
      ],
    );
  }
}

// ── Fenêtre Notifications ─────────────────────────────────────────────────────

class NotifWindowContent extends StatelessWidget {
  const NotifWindowContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SpatialWindowTitleBar(
          title: 'Notifications',
          icon: kNotifIcon,
          accentColor: SpatialTheme.accentNotif,
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            children: const [
              _NotifItem(
                app: 'Messages',
                message: 'Nouveau message de Sarah',
                time: '2 min',
                color: SpatialTheme.accentNotif,
              ),
              _NotifItem(
                app: 'GitHub',
                message: 'PR #42 merged successfully',
                time: '15 min',
                color: Color(0xFF6E7681),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _NotifItem extends StatelessWidget {
  const _NotifItem({
    required this.app,
    required this.message,
    required this.time,
    required this.color,
  });

  final String app;
  final String message;
  final String time;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      app,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: SpatialTheme.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontFamily: 'Inter',
                        color: SpatialTheme.textTertiary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                Text(
                  message,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: SpatialTheme.textPrimary,
                    fontSize: 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Fenêtre Horloge ───────────────────────────────────────────────────────────

class ClockWindowContent extends StatefulWidget {
  const ClockWindowContent({super.key});

  @override
  State<ClockWindowContent> createState() => _ClockWindowContentState();
}

class _ClockWindowContentState extends State<ClockWindowContent> {
  late DateTime _now;
  late Timer _timer;

  // Noms des jours et mois en français
  static const _jours = [
    'Lundi',
    'Mardi',
    'Mercredi',
    'Jeudi',
    'Vendredi',
    'Samedi',
    'Dimanche',
  ];
  static const _mois = [
    'janvier',
    'février',
    'mars',
    'avril',
    'mai',
    'juin',
    'juillet',
    'août',
    'septembre',
    'octobre',
    'novembre',
    'décembre',
  ];

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    // Timer.periodic déclenche setState exactement 1x/sec — coût négligeable
    // car l'horloge est isolée dans son propre widget
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer.cancel(); // Toujours annuler pour éviter les fuites
    super.dispose();
  }

  String get _timeString {
    final h = _now.hour.toString().padLeft(2, '0');
    final m = _now.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String get _dateString {
    final jour = _jours[_now.weekday - 1]; // weekday: 1=Lundi
    final mois = _mois[_now.month - 1]; // month: 1=Janvier
    return '$jour, ${_now.day} $mois ${_now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SpatialWindowTitleBar(
          title: 'Horloge',
          icon: kClockIcon,
          accentColor: SpatialTheme.accentClock,
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Secondes : barre de progression fine — donne vie à l'horloge
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: _SecondsBar(
                    seconds: _now.second,
                    accentColor: SpatialTheme.accentClock,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _timeString,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: SpatialTheme.textPrimary,
                    fontSize: 44,
                    fontWeight: FontWeight.w100,
                    letterSpacing: -2,
                  ),
                ),
                Text(
                  _dateString,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    color: SpatialTheme.textSecondary,
                    fontSize: 10,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Barre de progression des secondes [0–59] → [0%–100%]
class _SecondsBar extends StatelessWidget {
  const _SecondsBar({required this.seconds, required this.accentColor});
  final int seconds;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final progress = seconds / 59.0;
    return Stack(
      children: [
        // Track
        Container(
          height: 2,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(1),
          ),
        ),
        // Fill
        FractionallySizedBox(
          widthFactor: progress,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(1),
              boxShadow: [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.5),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
