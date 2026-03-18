import 'package:flutter/material.dart';

import '../core/spatial_window_data.dart';
import '../core/spatial_theme.dart';

// ── Icônes centralisées ──────────────────────────────────────────────────────
const IconData kWeatherIcon = Icons.cloud_outlined;
const IconData kNotifIcon = Icons.notifications_outlined;
const IconData kClockIcon = Icons.access_time_rounded;
const IconData kMusicIcon = Icons.music_note_rounded;

/// État global de toutes les fenêtres spatiales.
///
/// Utilise [ChangeNotifier] pour notifier l'UI uniquement lors d'un
/// changement structurel (drag, reorder z, etc.).
/// Le parallaxe gyroscopique, lui, est géré via [ValueNotifier] dans le
/// widget feuille → évite de rebuilder tout l'arbre pour chaque tick.
class SpatialWindowsController extends ChangeNotifier {
  SpatialWindowsController() {
    _windows = List<SpatialWindowData>.unmodifiable(_initialWindows());
  }

  late List<SpatialWindowData> _windows;
  List<SpatialWindowData> get windows => _windows;

  // ── Drag d'une fenêtre ──────────────────────────────────────────────────
  void updatePosition(String id, Offset delta) {
    _windows = [
      for (final w in _windows)
        w.id == id ? w.copyWith(position: w.position + delta) : w,
    ];
    notifyListeners();
  }

  // ── Amener une fenêtre au premier plan (z-order) ────────────────────────
  void bringToFront(String id) {
    final window = _windows.firstWhere((w) => w.id == id);
    final rest = _windows.where((w) => w.id != id).toList();
    _windows = List.unmodifiable([...rest, window]);
    notifyListeners();
  }

  // ── Initialisation ──────────────────────────────────────────────────────
  List<SpatialWindowData> _initialWindows() {
    return [
      const SpatialWindowData(
        id: 'weather',
        title: 'Météo',
        icon: kWeatherIcon,
        accentColor: SpatialTheme.accentWeather,
        position: Offset(20, 90),
        size: Size(320, 180),
        depth: 0.65,
      ),
      const SpatialWindowData(
        id: 'notif',
        title: 'Notifications',
        icon: kNotifIcon,
        accentColor: SpatialTheme.accentNotif,
        position: Offset(40, 310),
        size: Size(300, 140),
        depth: 0.45,
      ),
      const SpatialWindowData(
        id: 'clock',
        title: 'Horloge',
        icon: kClockIcon,
        accentColor: SpatialTheme.accentClock,
        position: Offset(30, 490),
        size: Size(280, 150),
        depth: 0.30,
      ),
      const SpatialWindowData(
        id: 'music',
        title: 'Music',
        icon: kMusicIcon,
        accentColor: SpatialTheme.accentMusic,
        position: Offset(25, 680),
        size: Size(340, 180),
        depth: 0.10,
      ),
    ];
  }
}
