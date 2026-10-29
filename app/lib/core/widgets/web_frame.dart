import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';
import '../web/pwa_install.dart';

/// Keeps the web build at phone width on tablets and PCs.
///
/// Wraps the Navigator (via `MaterialApp.builder`), so dialogs, bottom sheets
/// and snackbars stay inside the column. On a PC it also shows a QR code that
/// opens the site on a phone. Only used on web.
class WebFrame extends StatelessWidget {
  const WebFrame({super.key, required this.child});

  final Widget child;

  static const double appWidth = 480;
  static const double _frameBreakpoint = 600;
  static const double _panelBreakpoint = 960;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    if (width <= _frameBreakpoint) return child;

    // Tablets (iPadOS reports a Mac UA; PwaInstall detects it) get no panel.
    final showPanel =
        width >= _panelBreakpoint && PwaInstall.platform == PwaPlatform.other;

    return ColoredBox(
      color: AppColors.primaryBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (showPanel) ...[
            const _DesktopPanel(),
            const SizedBox(width: 64),
          ],
          Container(
            width: appWidth,
            decoration: const BoxDecoration(
              color: AppColors.white,
              boxShadow: [
                BoxShadow(color: AppColors.cardShadowMedium, blurRadius: 24),
              ],
            ),
            // Widgets that read the screen width lay out as on a phone.
            child: MediaQuery(
              data: media.copyWith(size: Size(appWidth, media.size.height)),
              child: ClipRect(child: child),
            ),
          ),
        ],
      ),
    );
  }
}

class _DesktopPanel extends StatelessWidget {
  const _DesktopPanel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final url = PwaInstall.siteOrigin;
    final host = Uri.tryParse(url)?.host ?? url;

    return Material(
      type: MaterialType.transparency,
      child: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/images/app_icon_small.png',
                    width: 48,
                    height: 48,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'MyCareNK',
                  style: GoogleFonts.googleSans(
                    color: AppColors.textPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              l10n.webDesktopTitle,
              style: GoogleFonts.googleSans(
                color: AppColors.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.webDesktopBody,
              style: GoogleFonts.googleSans(
                color: AppColors.textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: AppColors.primaryCardShadow, blurRadius: 16),
                ],
              ),
              child: QrImageView(
                data: url,
                size: 180,
                padding: EdgeInsets.zero,
                backgroundColor: AppColors.white,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: AppColors.textPrimary,
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              host,
              style: GoogleFonts.googleSans(
                color: AppColors.primaryDark,
                fontSize: 15,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              l10n.webDesktopContinue,
              style: GoogleFonts.googleSans(
                color: AppColors.textHint,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
