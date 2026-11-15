import 'package:flutter/material.dart';
import 'controllers/app_controller.dart';
import 'core/theme/arcana_theme.dart';
import 'presentation/screens/login_screen.dart';
import 'presentation/screens/main_hub_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final controller = AppController();
  controller.initializeFromStorage();
  runApp(ArcanaVttApp(controller: controller));
}

class ArcanaVttApp extends StatelessWidget {
  final AppController controller;

  const ArcanaVttApp({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        return MaterialApp(
          title: 'ArcanaVTT',
          debugShowCheckedModeBanner: false,
          theme: ArcanaThemeBuilder.build(
            controller.themeMode,
            controller.fontScale,
          ),
          home: controller.isAuthenticated
              ? MainHubScreen(controller: controller)
              : LoginScreen(controller: controller),
        );
      },
    );
  }
}
