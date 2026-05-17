import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';

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
  Widget build(BuildContext context) {
    return PopupMenuButton<_Language>(
      tooltip: 'เปลี่ยนภาษา',
      onSelected: (lang) => setState(() => _selected = lang),
      offset: const Offset(0, 50),
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
                  if (_selected.code == lang.code) ...[
                    const Spacer(),
                    const Icon(Icons.check, color: AppColors.primary, size: 18),
                  ],
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
