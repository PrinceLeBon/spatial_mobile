import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
                        style: GoogleFonts.inter(
                          color: SpatialTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Hans Zimmer',
                        style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
                          color: SpatialTheme.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        '18°',
                        style: GoogleFonts.inter(
                          color: SpatialTheme.textPrimary,
                          fontSize: 42,
                          fontWeight: FontWeight.w200,
                          height: 1.1,
                        ),
                      ),
                      Text(
                        'Partiellement nuageux',
                        style: GoogleFonts.inter(
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
          style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
                        color: SpatialTheme.textSecondary,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        color: SpatialTheme.textTertiary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
                Text(
                  message,
                  style: GoogleFonts.inter(
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

class ClockWindowContent extends StatelessWidget {
  const ClockWindowContent({super.key});

  @override
  Widget build(BuildContext context) {
    // Pour une démo statique on affiche une heure fixe.
    // En production : utiliser un Timer.periodic + setState ou stream.
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
                Text(
                  '22:41',
                  style: GoogleFonts.inter(
                    color: SpatialTheme.textPrimary,
                    fontSize: 44,
                    fontWeight: FontWeight.w100,
                    letterSpacing: -2,
                  ),
                ),
                Text(
                  'Mercredi, 18 mars 2026',
                  style: GoogleFonts.inter(
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
