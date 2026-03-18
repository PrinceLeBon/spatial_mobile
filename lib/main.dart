import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'ui/screens/spatial_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Immersive mode : masque la status bar système pour un rendu full-bleed
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Force orientation portrait uniquement pour le contrôle des axes gyro
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  runApp(const SpatialMobileApp());
}

class SpatialMobileApp extends StatelessWidget {
  const SpatialMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spatial Mobile',
      debugShowCheckedModeBanner: false,
      showPerformanceOverlay: true,
      // Thème minimal : on gère tout manuellement pour le contrôle maximal
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        // Désactive les splashes/highlights Material → pas d'artefact sur verre
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        splashColor: Colors.transparent,
      ),
      home: const SpatialHomeScreen(),
    );
  }
}
