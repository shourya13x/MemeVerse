import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/login_page.dart';
import 'screens/meme_home_page.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

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

  void toggleDarkMode(bool enabled) {
    setState(() {
      _themeMode = enabled ? ThemeMode.dark : ThemeMode.light;
    });
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
        return ColorScheme.fromSeed(
          brightness: brightness,
          seedColor: const Color(0xFFE91E63),
          primary: const Color(0xFFE91E63),
          secondary: const Color(0xFF2196F3),
          tertiary: const Color(0xFFFF9800),
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
          scrolledUnderElevation: 1,
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF2D3748),
          titleTextStyle: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF2D3748),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 12,
          shadowColor: const Color(0xFFE91E63).withAlpha(20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            shadowColor: const Color(0xFFE91E63).withAlpha(60),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
          shadowColor: const Color(0xFFE91E63).withAlpha(40),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            shadowColor: const Color(0xFFE91E63).withAlpha(80),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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
