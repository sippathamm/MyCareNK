import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../../core/constants/app_colors.dart';

/// Shared widget that displays recovery codes in a grid with a copy-all button.
/// Used by both RegistrationSuccessPage and RecoveryCodesDisplayPage.
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
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: recoveryCodes.map(_buildCodeBox).toList(),
        ),
        const SizedBox(height: 24),
        if (footerText != null) ...[
          Text(
            footerText!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 32),
        ],
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: recoveryCodes.join(', ')));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('คัดลอกรหัสทั้งหมดแล้ว')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.primary,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            child: const Text(
              'คัดลอกรหัสทั้งหมด',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ),
    );
  }
}
