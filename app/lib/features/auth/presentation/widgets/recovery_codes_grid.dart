import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../core/constants/app_colors.dart';

/// Shared widget that displays recovery codes in a grid with a copy-all button.
/// Used by RecoveryCodesDisplayPage.
class RecoveryCodesGrid extends StatelessWidget {
  final List<String> recoveryCodes;
  final String? footerText;

  const RecoveryCodesGrid({
    super.key,
    required this.recoveryCodes,
    this.footerText,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.2,
          children: recoveryCodes.map(_buildCodeBox).toList(),
        ),
        const SizedBox(height: 16),
        if (footerText != null) ...[
          Text(
            footerText!,
            textAlign: TextAlign.center,
            style: GoogleFonts.googleSans(
              fontSize: 12,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
        ],
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: recoveryCodes.join(', ')));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('คัดลอกรหัสทั้งหมดแล้ว', style: GoogleFonts.googleSans()),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.copy_outlined, size: 18),
            label: Text(
              'คัดลอกรหัสทั้งหมด',
              style: GoogleFonts.googleSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCodeBox(String code) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primaryCodeBox,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryCodeBorder),
      ),
      child: Center(
        child: Text(
          code,
          style: GoogleFonts.googleSans(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
