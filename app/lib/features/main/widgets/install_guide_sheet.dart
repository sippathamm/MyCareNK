import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/web/pwa_install.dart';
import '../../../core/widgets/gradient_button.dart';

/// Explains how to add the web build to the home screen. iOS has no install
/// prompt API, so it gets step-by-step Safari instructions; Android Chrome uses
/// the captured beforeinstallprompt when available.
class InstallGuideSheet extends StatefulWidget {
  const InstallGuideSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const InstallGuideSheet(),
    );
  }

  @override
  State<InstallGuideSheet> createState() => _InstallGuideSheetState();
}

class _InstallGuideSheetState extends State<InstallGuideSheet> {
  bool _isPrompting = false;

  Future<void> _install() async {
    setState(() => _isPrompting = true);
    final accepted = await PwaInstall.promptInstall();
    if (!mounted) return;
    if (accepted) {
      Navigator.of(context).pop();
    } else {
      setState(() => _isPrompting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final steps = switch (PwaInstall.platform) {
      PwaPlatform.ios => [
        (Icons.ios_share, l10n.installIosStep1),
        (Icons.add_box_outlined, l10n.installIosStep2),
        (Icons.check_circle_outline, l10n.installIosStep3),
      ],
      _ => [
        (Icons.more_vert, l10n.installAndroidStep1),
        (Icons.install_mobile_outlined, l10n.installAndroidStep2),
      ],
    };

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.asset(
                    'assets/images/app_icon_small.png',
                    width: 56,
                    height: 56,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    l10n.installAppTitle,
                    style: GoogleFonts.googleSans(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l10n.installAppSubtitle,
              style: GoogleFonts.googleSans(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            if (PwaInstall.isInAppBrowser)
              _InfoBox(text: l10n.installInAppBrowser)
            else if (PwaInstall.canPromptInstall)
              GradientButton(
                onPressed: _install,
                label: l10n.installNow,
                isLoading: _isPrompting,
              )
            else
              for (final (index, (icon, text)) in steps.indexed)
                _StepRow(number: index + 1, icon: icon, text: text),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                l10n.installLater,
                style: GoogleFonts.googleSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  final int number;
  final IconData icon;
  final String text;

  const _StepRow({
    required this.number,
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.primaryBackground,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$number',
              style: GoogleFonts.googleSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.googleSans(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Icon(icon, color: AppColors.primary, size: 22),
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String text;

  const _InfoBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.open_in_browser,
            color: AppColors.primaryDark,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.googleSans(
                fontSize: 14,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
