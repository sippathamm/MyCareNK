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
      LayoutBuilder(builder: (context, constraints) {
        final W = constraints.maxWidth;
        final slotSpacing = (W - nodeSize) / (n - 1);
        TextStyle labelStyle(int idx) {
          final active = idx <= step;
          return GoogleFonts.googleSans(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: active ? AppColors.primary : AppColors.textMuted,
          );
        }
        return SizedBox(
          height: 16,
          child: Stack(clipBehavior: Clip.none, children: [
            Positioned(left: 0, top: 0, child: Text(labels[0], style: labelStyle(0))),
            Positioned(right: 0, top: 0, child: Text(labels[n - 1], style: labelStyle(n - 1))),
            for (int i = 1; i < n - 1; i++)
              Positioned(
                left: nodeSize / 2 + i * slotSpacing,
                top: 0,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, 0),
                  child: Text(labels[i], style: labelStyle(i)),
                ),
              ),
          ]),
        );
      }),
    ]),
  );
}
