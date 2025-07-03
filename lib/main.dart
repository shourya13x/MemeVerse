import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_page.dart';
import 'screens/meme_home_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MemeApp());
}

class MemeApp extends StatefulWidget {
  const MemeApp({super.key});

  @override
  State<MemeApp> createState() => _MemeAppState();
}

class _MemeAppState extends State<MemeApp> {
  ThemeMode _themeMode = ThemeMode.light;
  String _themeColor = 'Default';

  @override
  void initState() {
    super.initState();
    _loadThemeMode();
  }

  /// Loads the saved theme mode from persistent storage
  Future<void> _loadThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final isDark = prefs.getBool('isDarkMode') ?? false;
    setState(() {
      _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    });
  }

  /// Saves the theme mode to persistent storage
  Future<void> _saveThemeMode(bool isDark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isDarkMode', isDark);
  }

  void toggleDarkMode(bool enabled) {
    setState(() {
      _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    });
    _saveThemeMode(enabled);
  }

  void setThemeColor(String color) {
    setState(() {
      _themeColor = color;
    });
  }

  ColorScheme _getColorScheme(Brightness brightness) {
    switch (_themeColor) {
      case 'Blue':
        return ColorScheme.fromSeed(
          brightness: brightness,
          seedColor: const Color(0xFF2196F3),
          primary: const Color(0xFF2196F3),
          secondary: const Color(0xFFE91E63),
          tertiary: const Color(0xFFFF9800),
        );
      case 'Green':
        return ColorScheme.fromSeed(
          brightness: brightness,
          seedColor: const Color(0xFF4CAF50),
          primary: const Color(0xFF4CAF50),
          secondary: const Color(0xFF2196F3),
          tertiary: const Color(0xFFFF9800),
        );
      case 'Orange':
        return ColorScheme.fromSeed(
          brightness: brightness,
          seedColor: const Color(0xFFFF9800),
          primary: const Color(0xFFFF9800),
          secondary: const Color(0xFFE91E63),
          tertiary: const Color(0xFF2196F3),
        );
      default:
        // Arc browser inspired deep blue theme
        return ColorScheme.fromSeed(
          brightness: brightness,
          seedColor: const Color(0xFF4C6EF5), // Arc browser blue
          primary: const Color(0xFF4C6EF5), // Arc primary blue
          primaryContainer:
              brightness == Brightness.light
                  ? const Color(0xFF4C6EF5).withAlpha(15)
                  : const Color(0xFF4C6EF5).withAlpha(30),
          secondary: const Color(0xFF364FC7), // Arc darker blue
          secondaryContainer:
              brightness == Brightness.light
                  ? const Color(0xFF364FC7).withAlpha(15)
                  : const Color(0xFF364FC7).withAlpha(30),
          tertiary: const Color(0xFF3B82F6), // Arc bright blue accent
          tertiaryContainer:
              brightness == Brightness.light
                  ? const Color(0xFF3B82F6).withAlpha(15)
                  : const Color(0xFF3B82F6).withAlpha(30),
          surface:
              brightness == Brightness.light
                  ? const Color(0xFFFAFBFF) // Slightly blue-tinted white
                  : const Color(0xFF0A0E1A), // Deep blue-black
          surfaceContainerHighest:
              brightness == Brightness.light
                  ? const Color(0xFFF4F6FF) // Light blue-tinted surface
                  : const Color(0xFF1A1F33), // Dark blue surface
          background:
              brightness == Brightness.light
                  ? const Color(0xFFF8FAFF) // Very light blue background
                  : const Color(0xFF0A0E1A),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Meme Explorer',
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: _getColorScheme(Brightness.light),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 2,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actionsIconTheme: const IconThemeData(color: Colors.white),
        ),
        cardTheme: CardThemeData(
          elevation: 12,
          shadowColor: const Color(0xFF4C6EF5).withAlpha(25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          surfaceTintColor: const Color(0xFF4C6EF5).withAlpha(6),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            shadowColor: const Color(0xFF4C6EF5).withAlpha(60),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFF4C6EF5),
          foregroundColor: Colors.white,
          splashColor: const Color(0xFF364FC7).withAlpha(80),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: _getColorScheme(Brightness.dark),
        appBarTheme: AppBarTheme(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 1,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 12,
          shadowColor: const Color(0xFF4C6EF5).withAlpha(40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          surfaceTintColor: const Color(0xFF4C6EF5).withAlpha(8),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            shadowColor: const Color(0xFF4C6EF5).withAlpha(80),
            foregroundColor: Colors.white,
            textStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          backgroundColor: const Color(0xFF4C6EF5),
          foregroundColor: Colors.white,
          splashColor: const Color(0xFF364FC7).withAlpha(100),
        ),
      ),
      themeMode: _themeMode,
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
            return MemeHomePage(
              isDarkMode: _themeMode == ThemeMode.dark,
              onToggleDarkMode: toggleDarkMode,
              themeColor: _themeColor,
              onThemeColorChanged: setThemeColor,
            );
          }
          return const LoginPage();
        },
      ),
    );
  }
}

String getImageUrl(String url) {
  if (kIsWeb) {
    return 'https://corsproxy.io/?$url';
  }
  return url;
}
