import 'package:flutter/material.dart';

import '../../core/spatial_theme.dart';

/// Barre de titre commune à toutes les fenêtres spatiales.
///
/// Implémentée en const autant que possible pour éviter tout rebuild inutile.
class SpatialWindowTitleBar extends StatelessWidget {
  const SpatialWindowTitleBar({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
  });

  final String title;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 0.5,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Row(
          children: [
            Icon(icon, size: 13, color: accentColor),
            const SizedBox(width: 7),
            Text(
              title,
              style: TextStyle(fontFamily: 'Inter', 
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: SpatialTheme.textPrimary,
                letterSpacing: 0.3,
              ),
            ),
            const Spacer(),
            // Boutons macOS-like (cosmétiques)
            _TrafficLight(color: const Color(0xFFFF6058)),
            const SizedBox(width: 5),
            _TrafficLight(color: const Color(0xFFFFBD2E)),
            const SizedBox(width: 5),
            _TrafficLight(color: const Color(0xFF28CA41)),
          ],
        ),
      ),
    );
  }
}

class _TrafficLight extends StatelessWidget {
  const _TrafficLight({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 9,
      height: 9,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.7),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 3),
        ],
      ),
    );
  }
}
