import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../features/service/presentation/pages/request_history_page.dart';

class ShortcutMenu extends StatelessWidget {
  const ShortcutMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _buildShortcutItem(context: context, icon: Icons.location_on, label: 'สถานบริการ'),
        const SizedBox(width: 16),
        _buildShortcutItem(context: context, icon: Icons.menu_book, label: 'คู่มือการใช้'),
        const SizedBox(width: 16),
        _buildShortcutItem(context: context, icon: Icons.receipt_long, label: 'ประวัติการขอ'),
      ],
    );
  }

  Widget _buildShortcutItem({
    required BuildContext context,
    required IconData icon,
    required String label,
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
                if (label == 'ประวัติการขอ') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const RequestHistoryPage(),
                    ),
                  );
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
                  Icon(icon, color: AppColors.primary, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
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
