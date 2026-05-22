import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../../core/l10n/locale_provider.dart';

class _Language {
  final String flag;
  final String name;
  final String code;
  const _Language(this.flag, this.name, this.code);
}

const _languages = [
  _Language('🇹🇭', 'ไทย', 'th'),
  _Language('🇱🇦', 'ລາວ', 'lo'),
  _Language('🇲🇲', 'မြန်မာ', 'my'),
];

class LanguageSwitcher extends StatefulWidget {
  const LanguageSwitcher({super.key});

  @override
  State<LanguageSwitcher> createState() => _LanguageSwitcherState();
}

class _LanguageSwitcherState extends State<LanguageSwitcher> {
  _Language _selected = _languages.first;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentCode = LocaleProvider.of(context).locale.languageCode;
    final match = _languages.where((l) => l.code == currentCode).firstOrNull;
    if (match != null && match.code != _selected.code) {
      _selected = match;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = LocaleProvider.of(context);

    return PopupMenuButton<_Language>(
      tooltip: AppLocalizations.of(context).changeLanguage,
      onSelected: (lang) {
        setState(() => _selected = lang);
        provider.onLocaleChange(Locale(lang.code));
      },
      offset: const Offset(0, 50),
      color: AppColors.avatarBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      itemBuilder: (context) => _languages
          .map(
            (lang) => PopupMenuItem<_Language>(
              value: lang,
              child: Row(
                children: [
                  Text(lang.flag, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 10),
                  Text(
                    lang.name,
                    style: GoogleFonts.googleSans(
                      fontSize: 15,
                      fontWeight: _selected.code == lang.code
                          ? FontWeight.bold
                          : FontWeight.normal,
                      color: _selected.code == lang.code
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                  ),
                  const Spacer(),
                  Opacity(
                    opacity: _selected.code == lang.code ? 1.0 : 0.0,
                    child: const Icon(Icons.check, color: AppColors.primary, size: 18),
                  ),
                ],
              ),
            ),
          )
          .toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.avatarBackground,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_selected.flag, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            Text(
              _selected.name,
              style: GoogleFonts.googleSans(
                color: AppColors.avatarIcon,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down,
              color: AppColors.avatarIcon,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
