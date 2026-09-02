import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final savedMode = prefs.getString('themeMode');
  if (savedMode != null) {
    themeNotifier.value = ThemeMode.values.firstWhere(
      (m) => m.name == savedMode,
      orElse: () => ThemeMode.system,
    );
  }
  runApp(const EVApp());
}

class EVApp extends StatelessWidget {
  const EVApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'EV',
          themeMode: currentMode,
          theme: ThemeData(
            brightness: Brightness.light,
            colorSchemeSeed: const Color(0xFF6366F1),
            useMaterial3: true,
            fontFamily: 'sans-serif',
            cardTheme: CardTheme(
              elevation: 0,
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: const Color(0xFF94A3B8).withOpacity(0.12),
                  width: 1.2,
                ),
              ),
            ),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
            ),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorSchemeSeed: const Color(0xFF6366F1),
            useMaterial3: true,
            fontFamily: 'sans-serif',
            scaffoldBackgroundColor: const Color(0xFF0B0F19),
            cardTheme: CardTheme(
              elevation: 0,
              color: const Color(0xFF151D30),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: const Color(0xFF243049).withOpacity(0.4),
                  width: 1.2,
                ),
              ),
            ),
            appBarTheme: const AppBarTheme(
              elevation: 0,
              centerTitle: true,
              backgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
            ),
          ),
          home: FutureBuilder<bool>(
            future: _checkOnboarding(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return snapshot.data! ? const HomeScreen() : const OnboardingScreen();
            },
          ),
        );
      },
    );
  }

  Future<bool> _checkOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('onboarding_completed') ?? false;
  }
}
