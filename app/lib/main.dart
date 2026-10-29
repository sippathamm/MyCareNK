import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/constants/app_colors.dart';
import 'core/l10n/app_localizations.dart';
import 'core/l10n/locale_provider.dart';
import 'core/widgets/web_frame.dart';
import 'features/main/presentation/pages/main_page.dart';
import 'features/scan/data/zxing_script.dart';

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

  // Must run before the first scanner start(): mobile_scanner keeps the first
  // URL it is given. No-op on native platforms.
  MobileScannerPlatform.instance.setBarcodeLibraryScriptUrl(kZxingScriptUrl);

  LicenseRegistry.addLicense(() async* {
    final ofl = await rootBundle.loadString('assets/fonts/noto_sans_thai/OFL.txt');
    yield LicenseEntryWithLineBreaks(['NotoSansThai'], ofl);
  });

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
            // Native platforms use the system Thai font.
            fontFamilyFallback: kIsWeb ? const ['NotoSansThai'] : null,
          ),
        ),
        home: const MainScreen(),
        builder: kIsWeb
            ? (context, child) => WebFrame(child: child ?? const SizedBox())
            : null,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
