import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';

/// White rounded card with a gradient header (icon + title) above a padded
/// [child]. Shared by the condom-request and consultation-booking sections.
/// [headerColors] overrides the default primary gradient (e.g. the lubricant
/// gradient used by the consultation-booking flow).
class SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;
  final EdgeInsetsGeometry margin;
  final List<Color>? headerColors;

  const SectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.child,
    this.margin = const EdgeInsets.only(bottom: 20),
    this.headerColors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadowMedium,
              blurRadius: 10,
              offset: Offset(0, 4)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: headerColors ??
                      const [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(children: [
                Icon(icon, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(title,
                    style: GoogleFonts.googleSans(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
            Padding(padding: const EdgeInsets.all(16), child: child),
          ],
        ),
      ),
    );
  }
}
