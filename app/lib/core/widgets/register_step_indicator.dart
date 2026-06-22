import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../l10n/app_localizations.dart';

Widget buildRegisterStepIndicator(BuildContext context, int step) {
  final l10n = AppLocalizations.of(context);
  final labels = [l10n.registerStep1, l10n.registerStep2, l10n.registerStep3];
  const double nodeSize = 34;
  const double gap = 6;
  final n = labels.length;

  TextStyle labelStyle(int idx) {
    final active = idx <= step;
    return GoogleFonts.googleSans(
      fontSize: 11,
      fontWeight: active ? FontWeight.w700 : FontWeight.w400,
      color: active ? AppColors.primary : AppColors.textMuted,
    );
  }

  final iconItems = <Widget>[];
  for (int idx = 0; idx < n; idx++) {
    final isDone = idx < step;
    final isCurrent = idx == step;
    final active = isDone || isCurrent;
    final isLast = idx == n - 1;
    final showCheck = isDone || (isCurrent && isLast);
    iconItems.add(AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: nodeSize,
      height: nodeSize,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : const Color(0xFFE8E8E8),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: showCheck
            ? const Icon(Icons.check, color: Colors.white, size: 16)
            : Text(
                '${idx + 1}',
                style: GoogleFonts.googleSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: active ? Colors.white : AppColors.textMuted,
                ),
              ),
      ),
    ));
    if (!isLast) {
      iconItems.addAll([
        const SizedBox(width: gap),
        Expanded(
          child: Container(
            height: 3,
            decoration: BoxDecoration(
              color: idx < step ? AppColors.primary : const Color(0xFFE8E8E8),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(width: gap),
      ]);
    }
  }

  return Padding(
    padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
    child: Column(children: [
      Row(children: iconItems),
      const SizedBox(height: 4),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(labels[0], style: labelStyle(0))),
          Expanded(
            child: Text(
              labels[1],
              style: labelStyle(1),
              textAlign: TextAlign.center,
            ),
          ),
          Expanded(
            child: Text(
              labels[2],
              style: labelStyle(2),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    ]),
  );
}
