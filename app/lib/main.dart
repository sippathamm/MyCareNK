import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_colors.dart';
import 'core/l10n/app_localizations.dart';
import 'core/l10n/locale_provider.dart';
import 'features/main/presentation/pages/main_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Injected at build time via `--dart-define-from-file=.env` so the config is
  // never bundled as a downloadable asset (it would be public on web).
  const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
  if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
    throw StateError(
      'SUPABASE_URL / SUPABASE_ANON_KEY missing — run with --dart-define-from-file=.env',
    );
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);

  runApp(const MyCareNKApp());
}

class MyCareNKApp extends StatefulWidget {
  const MyCareNKApp({super.key});

  @override
  State<MyCareNKApp> createState() => _MyCareNKAppState();
}

class _MyCareNKAppState extends State<MyCareNKApp> {
  Locale _locale = const Locale('th');

  void _setLocale(Locale locale) => setState(() => _locale = locale);

  @override
  Widget build(BuildContext context) {
    return LocaleProvider(
      locale: _locale,
      onLocaleChange: _setLocale,
      child: MaterialApp(
        title: 'MyCareNK',
        locale: _locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.primaryLight,
            error: AppColors.error,
            surface: AppColors.white,
          ),
          scaffoldBackgroundColor: AppColors.white,
          textTheme: GoogleFonts.googleSansTextTheme(
            ThemeData.light().textTheme,
          ).apply(
            bodyColor: AppColors.textPrimary,
            displayColor: AppColors.textPrimary,
          ),
        ),
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
