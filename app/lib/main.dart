import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'features/main/presentation/pages/main_screen.dart';

void main() {
  runApp(const MyCareNKApp());
}

class MyCareNKApp extends StatelessWidget {
  const MyCareNKApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyCareNK',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF8A50),
          primary: const Color(0xFFFF8A50),
          secondary: const Color(0xFFFFB58A),
          error: const Color(0xFFFF4D4D),
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.promptTextTheme(Theme.of(context).textTheme)
            .apply(
              bodyColor: const Color(0xFF333333),
              displayColor: const Color(0xFF333333),
            ),
      ),
      home: const MainScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
