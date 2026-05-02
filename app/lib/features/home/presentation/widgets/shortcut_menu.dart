import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../features/service/presentation/pages/request_history_page.dart';

class ShortcutMenu extends StatelessWidget {
  final VoidCallback? onNavigateToHistory;

  const ShortcutMenu({super.key, this.onNavigateToHistory});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildShortcutItem(
          context: context,
          icon: Icons.location_on_outlined,
          label: 'สถานบริการ',
          iconColor: AppColors.primary,
          iconBg: AppColors.statusPendingLight,
        ),
        const SizedBox(width: 16),
        _buildShortcutItem(
          context: context,
          icon: Icons.menu_book_outlined,
          label: 'คู่มือการใช้',
          iconColor: AppColors.lubricant,
          iconBg: AppColors.lubricantCardStart,
        ),
        const SizedBox(width: 16),
        _buildShortcutItem(
          context: context,
          icon: Icons.receipt_long_outlined,
          label: 'ประวัติคำขอ',
          iconColor: const Color(0xFF7C4DFF),
          iconBg: AppColors.avatarBackground,
        ),
      ],
    );
  }

  Widget _buildShortcutItem({
    required BuildContext context,
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
                if (label == 'ประวัติคำขอ') {
                  if (onNavigateToHistory != null) {
                    onNavigateToHistory!();
                  } else {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const RequestHistoryPage(),
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('"$label" ถูกกด')),
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
                    style: const TextStyle(
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
