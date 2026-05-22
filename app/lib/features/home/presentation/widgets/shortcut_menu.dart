import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/l10n/app_localizations.dart';
import '../../../../features/service/presentation/pages/request_history_page.dart';
import '../pages/service_centers_page.dart';

enum _ShortcutType { serviceCenters, guide, requestHistory }

class ShortcutMenu extends StatelessWidget {
  final VoidCallback? onNavigateToHistory;

  const ShortcutMenu({super.key, this.onNavigateToHistory});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        _buildShortcutItem(
          context: context,
          type: _ShortcutType.serviceCenters,
          icon: Icons.location_on_outlined,
          label: l10n.serviceCenters,
          iconColor: AppColors.statusReady,
          iconBg: AppColors.statusReadyLight,
        ),
        const SizedBox(width: 16),
        _buildShortcutItem(
          context: context,
          type: _ShortcutType.guide,
          icon: Icons.menu_book_outlined,
          label: l10n.guide,
          iconColor: AppColors.lubricant,
          iconBg: AppColors.statusPreparingLight,
        ),
        const SizedBox(width: 16),
        _buildShortcutItem(
          context: context,
          type: _ShortcutType.requestHistory,
          icon: Icons.receipt_long_outlined,
          label: l10n.requestHistory,
          iconColor: AppColors.statusCompleted,
          iconBg: AppColors.statusCompletedLight,
        ),
      ],
    );
  }

  Widget _buildShortcutItem({
    required BuildContext context,
    required _ShortcutType type,
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color iconBg,
  }) {
    return Expanded(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: AppColors.cardShadow,
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: () {
                switch (type) {
                  case _ShortcutType.requestHistory:
                    if (onNavigateToHistory != null) {
                      onNavigateToHistory!();
                    } else {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const RequestHistoryPage(),
                        ),
                      );
                    }
                  case _ShortcutType.serviceCenters:
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ServiceCentersPage(),
                      ),
                    );
                  case _ShortcutType.guide:
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppLocalizations.of(context).shortcutPressed(label)),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                }
              },
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: iconBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: iconColor, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: GoogleFonts.googleSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
